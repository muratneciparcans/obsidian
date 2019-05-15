module vm;
import std.string : format;
import interlang;
import obsobject;
import builtin;
import std.stdio;

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
        OBSObject* stack = cast(OBSObject*) new OBSObject[1024 * 128]; // Object

        

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
            stack++;
            *stack = new RArray;
            IP++;
            goto start;
        case il.apush:
            (*cast(RArray*) stack).push(current);
            IP++;
            goto start;
        case il.opIndex:
            current = (*cast(OBSObject*) stack)[current];
            stack--;
            IP++;
            goto start;
        case il.opIndexAssign:
            (*cast(OBSObject*)(stack - 1))[*cast(OBSObject*) stack] = current;
            stack-=2;
            IP++;
            goto start;
        case il.astore:
            current = *stack;
            stack--;
            IP++;
            goto start;
        case il.push:
            stack++;
            *stack = current;
            IP++;
            goto start;
            /**  put active object to the stack as function parameter */
        case il.pushparam:
            stack++;
            *stack = current;
            IP++;
            goto start;
            /** - Operation
			 *  Subtract the active object from the object loaded into the stack and delete the object from the stack
			 */
        case il.sub:
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
            writeln("Object");
            writeln(*IP);
            goto start;
            /** + Operation
			 *  Add the active object with the object loaded into the stack and delete the object from stack.
			 */
        case il.add:
            current = *stack + current;
            stack--;
            IP++;
            goto start;
            /** / Operation
			 *  Split the object inserted into the active object stack into the and delete the object from stack.
			 */
        case il.div:
            current = *stack / current;
            stack--;
            IP++;
            goto start;
            /** * Operation
			 *  Multiply the active object with the object loaded into the Stack and delete the object from stack.
			 */
        case il.mul:
            current = *stack * current;
            stack--;
            IP++;
            goto start;
        case il.eq:
            current = *stack == current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.neq:
            current = *stack == current ? _false : _true;
            stack--;
            IP++;
            goto start;
        case il.lt:
            current = *stack < current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.le:
            current = *stack <= current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.gt:
            current = *stack > current ? _true : _false;
            stack--;
            IP++;
            goto start;
        case il.ge:
            current = *stack >= current ? _true : _false;
            stack--;
            IP++;
            goto start;
            /** CALL
			 *  Take the parameters of the function to be called from the stack, throw them into an array and empty the stack
			 *  Note : The parameter number of the function to be called comes within IL output
			 */
        case il.call:
            IP++;
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
