module vm;
import std.string : format;
import interlang;
import obsobject;
import builtin;
import std.stdio;
import core.memory : GC;

// OBSObject

class VirtualMachine
{
    static OBSObject[string] global;
    static this()
    {
        // dfmt off
        global = [
            "print" : new RFunction("print", &builtin._print),
            "dice" : new RFunction("dice", &builtin._rnd_dice),
            "uniform" : new RFunction("uniform", &builtin._uniform),
        ];
        // dfmt on
    }

    void execute(IL ilcode)
    {
        // ilcode.codes.writeln();
        string tmp; // A string to use temporarily
        /* The stack is walked through a raw pointer, so the slice itself is
           registered as a GC root: otherwise the collector could free the
           buffer while the machine is still running on it. */
        enum size_t stackSlots = 1024 * 128; // Object stack, 128K slots
        auto stackBuffer = new OBSObject[stackSlots];
        GC.addRoot(stackBuffer.ptr);
        scope (exit)
            GC.removeRoot(stackBuffer.ptr);
        OBSObject* stackBase = stackBuffer.ptr;
        OBSObject* stackLimit = stackBase + stackSlots;
        OBSObject* stack = stackBase;

        /* Every push and pop stays inside the allocated range. */
        void needRoom()
        {
            if (stack + 1 >= stackLimit)
                throw new Exception("VM yığını taştı (%s slot).".format(stackSlots));
        }

        void needValues(size_t count)
        {
            if (stack < stackBase + count)
                throw new Exception("VM yığınında %s değer bekleniyordu.".format(count));
        }

        OBSObject current; // Current object
        OBSObject[string] variables; // Variables
        auto IP = ilcode.codes.ptr; // Instruction Pointer.
    start:
        switch (*cast(il*) IP)
        {    ///  go to IL instructions step by step.
            /** Changes the active object to be manipulated.  */
        case il.load:
            IP++;
            current = *cast(OBSObject*) IP;
            IP += (void*).sizeof;
            goto start;
            /** Define the active variable "hashmap" by the variable name.  */
        case il.definevar:
            IP++;
            tmp = (cast(char*) IP).cstr2dstr();
            variables[tmp] = current;
            IP += tmp.length + 1;
            goto start;
            /** First search the variables in user side ( source code ) if there is no then,
			 *  search on global variables
			 */
        case il.loadvar:
            IP++;
            tmp = (cast(char*) IP).cstr2dstr();
            if (auto var = tmp in variables)
                current = *var;
            else if (auto var = tmp in global)
            {
                current = *var;
            }
            else
                throw new Exception("'%s' variable not defined!".format(tmp));
            IP += tmp.length + 1;
            goto start;
            /** put the active object inside stack */
        case il.newarray:
            needRoom();
            stack++;
            *stack = new RArray;
            IP++;
            goto start;
        case il.apush:
            needValues(1);
            auto target = cast(RArray) *stack;
            if (target is null)
                throw new Exception("apush yalnızca dizi üzerinde çalışır.");
            target.push(current);
            IP++;
            goto start;
        case il.opIndex:
            needValues(1);
            current = (*cast(OBSObject*) stack)[current];
            stack--;
            IP++;
            goto start;
        case il.opIndexAssign:
            needValues(2);
            (*cast(OBSObject*)(stack - 1))[*cast(OBSObject*) stack] = current;
            stack-=2;
            IP++;
            goto start;
        case il.astore:
            needValues(1);
            current = *stack;
            stack--;
            IP++;
            goto start;
        case il.push:
            needRoom();
            stack++;
            *stack = current;
            IP++;
            goto start;
            /**  put active object to the stack as function parameter */
        case il.pushparam:
            needRoom();
            stack++;
            *stack = current;
            IP++;
            goto start;
            /** - Operation
			 *  Subtract the active object from the object loaded into the stack and delete the object from the stack
			 */
        case il.sub:
            needValues(1);
            current = *stack - current;
            --stack;
            IP++;
            goto start;
        case il.jz:
            IP++;
            if (current.toBool())
            {
                IP += size_t.sizeof;
            }
            else
            {
                IP = ilcode.codes.ptr + *cast(size_t*) IP;
            }
            goto start;
        case il.jnz:
            IP++;
            if (current.toBool())
            {
                IP = ilcode.codes.ptr + *cast(size_t*) IP;
            }
            else
            {
                IP += size_t.sizeof;
            }
            goto start;
        case il.getproperty:
            IP++;
            tmp = (cast(char*) IP).cstr2dstr();
            IP += tmp.length + 1;
            current = current.getProperty(tmp);
            goto start;
        case il.jmp:
            IP++;
            IP = ilcode.codes.ptr + *cast(size_t*) IP;
            // writeln("Object");
            // writeln(*IP);
            goto start;
            /** + Operation
			 *  Add the active object with the object loaded into the stack and delete the object from stack.
			 */
        case il.add:
            needValues(1);
            current = *stack + current;
            stack--;
            IP++;
            goto start;
            /** / Operation
			 *  Split the object inserted into the active object stack into the and delete the object from stack.
			 */
        case il.div:
            needValues(1);
            current = *stack / current;
            stack--;
            IP++;
            goto start;
            /** * Operation
			 *  Multiply the active object with the object loaded into the Stack and delete the object from stack.
			 */
        case il.mul:
            needValues(1);
            current = *stack * current;
            stack--;
            IP++;
            goto start;
        case il.eq:
            needValues(1);
            current = *stack == current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.neq:
            needValues(1);
            current = *stack == current ? _false : _true;
            stack--;
            IP++;
            goto start;
        case il.lt:
            needValues(1);
            current = *stack < current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.le:
            needValues(1);
            current = *stack <= current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.gt:
            needValues(1);
            current = *stack > current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.ge:
            needValues(1);
            current = *stack >= current ? _true : _false;
            stack--;
            IP++;
            goto start;
            /** CALL
			 *  Take the parameters of the function to be called from the stack, throw them into an array and empty the stack
			 *  Note : The parameter number of the function to be called comes within IL output
			 */
            /** Non short-circuiting logical operations. The parser lowers
                and/or to jz/jnz, so these exist for IL produced by other means. */
        case il.and:
            needValues(1);
            current = (*stack).toBool() ? current : *stack;
            stack--;
            IP++;
            goto start;
        case il.or:
            needValues(1);
            current = (*stack).toBool() ? *stack : current;
            stack--;
            IP++;
            goto start;
        case il.call:
            IP++;
            needValues(*cast(size_t*) IP + 1);
            current = (*(stack - *cast(size_t*) IP))(
                    (stack - *cast(size_t*) IP + 1)[0 .. *cast(size_t*) IP]);
            stack -= *cast(size_t*) IP + 1;
            IP += size_t.sizeof;
            goto start;
            /** Stop the machine. */
        case il.hlt:
            break;
        default:
            throw new Exception("Unknown operand code %s".format(*cast(il*) IP));
        }
    }
}
