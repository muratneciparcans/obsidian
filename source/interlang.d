import interlang;
import std.string;
import core.stdc.string: strlen;
import std.conv;
import std.stdio;
import obsobject;

auto cstr2dstr(inout(char)* cstr){
	return cast(string) (cstr ? cstr[0 .. strlen(cstr)] : "");
}

/**
 * List of Operand Code.
 * We can define only 255 operands in ubyte.
*/
enum il : ubyte{
	hlt,
	load, loadvar, definevar,
	push, pushparam, call,
	add, sub, div, mul,

	eq, lt, le, gt, ge, neq,

	and, or, getproperty,

	apush, newarray, astore, opIndex, opIndexAssign,

	jnz, jz, jmp,
}

class IL{
	ubyte[] codes;
	OBSObject[] objects;

	void load(OBSObject addr){
		objects ~= addr;
		codes ~= il.load;
		codes ~= (cast(ubyte*) &addr)[0..(void*).sizeof];
	}

	size_t load(size_t val){
		codes ~= (cast(ubyte*) &val)[0..val.sizeof];
		
		return codes.length - val.sizeof;
	}

	void load(size_t val, size_t pos){
		codes[pos..pos + val.sizeof]= (cast(ubyte*) &val)[0..val.sizeof];
	}


	size_t pos(){
	    return codes.length;
	}

	/* load functions */
	void load(int val){
		load(new RNumber(val));
	}
	void load(bool val){
		load(new RBoolean(val));
	}
	void load(string val){
		load(new RString(val));
	}
	/* function to load variable */
	void loadvar(string name){
		codes ~= il.loadvar;
		codes ~= cast(ubyte[]) name;
		codes ~= 0x00;///Bitiş karakteri
	}
	/* function to define a variable */
	void definevar(string name){
		codes ~= il.definevar;
		codes ~= cast(ubyte[]) name;
		codes ~= 0x00;
		
	}
	/* call a function */
	void call(size_t parameter_count){
		codes ~= il.call;
		codes ~= (cast(ubyte*) &parameter_count)[0..size_t.sizeof];
	}
	/* push params to stack */
	void pushparam(){
		codes ~= il.pushparam;
	}
	/* push to stack */
	void push(){
		codes ~= il.push;
	}
	void newarray(){
		codes ~= il.newarray;
	}
	void opIndexAssign(){
		codes ~= il.opIndexAssign;
	}
	void apush(){
		codes ~= il.apush;
	}
	void astore(){
		codes ~= il.astore;
	}
	void opIndex(){
		codes ~= il.opIndex;
	}
	void getProperty(string name){
		codes ~= il.getproperty;
		codes ~= cast(ubyte[]) name;
		codes ~= 0x00; /// End Character
	}
	/* Addition */
	void add(){
		codes ~= il.add;
	}
	/* Subtraction */
	void sub(){
		codes ~= il.sub;
	}
	/* Division */
	void div(){
		codes ~= il.div;
	}
	/* Multiplication */
	void mul(){
		codes ~= il.mul;
	}
	/* Stop the machine */
	void hlt(){
		codes ~= il.hlt;
	}
	size_t jnz(size_t pos = 0){
		codes ~= il.jnz;
		return load(pos);
	}
	size_t jz(size_t pos = 0){
		codes ~= il.jz;
		return load(pos);
	}
	size_t jmp(size_t pos = 0){
		codes ~= il.jmp;
		return load(pos);
	}
	/* Generate IL code */
	void newcode(il code){
		codes ~= code;
	}
	/* Assembly style IR output. */
	@property override string toString() const{
		string output;
		auto ptr = codes.ptr;
		start:
		switch(*cast(il*) ptr){
			case il.loadvar, il.getproperty:
			    il opname = *cast(il*) ptr;
			    ptr++;
				string name = (cast(char*) ptr).cstr2dstr();
				output ~= "%s %s\n".format(opname, name);
				ptr += name.length + 1;
				
				goto start;
			case il.definevar: ptr++;
				string name = (cast(char*) ptr).cstr2dstr();
				output ~= "definevar %s\n".format(name);
				ptr += name.length + 1;
				goto start;
			case il.push, il.pushparam, il.sub, il.add, il.div, il.mul,
			        il.newarray, il.apush, il.astore, il.opIndex, il.opIndexAssign,
			        il.and, il.or,
			        il.eq, il.neq, il.gt, il.ge, il.lt, il.le:
				output ~= "%s\n".format(*cast(il*) ptr);
				ptr++;
				goto start;
			case il.load: ptr++;
				OBSObject addr = *cast(OBSObject*) ptr;
				output ~= "load \"%s\"\n".format(addr.toString().replace("\"", "\"\""));
				ptr += (void*).sizeof;
				goto start;
			case il.call: ptr++;
				size_t addr = *cast(size_t*) ptr;
				output ~= "call %s\n".format(addr);
				ptr += size_t.sizeof;
				goto start;
			case il.jz, il.jnz, il.jmp:
			    il opname = *cast(il*) ptr;
			    ptr++;
				size_t addr = *cast(size_t*) ptr;
				output ~= "%s %s\n".format(opname, addr);
				ptr += size_t.sizeof;
				goto start;
			case il.hlt: ptr++;
			    // ptr.writeln();
                output ~= "HLT\n";
                break;
			default:
				throw new Exception("Unknown operand code %s".format(*cast(il*) ptr));
		}
		return output;
	}
}