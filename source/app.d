import fcgi.stdio;
import parser;
import obsobject;
import vm;
import std.file;
import std.getopt;
import std.concurrency;


// string readFromStdIn()
// {
//     string output;
//     char[] buf;

//     while (stdin.readln(buf))
//     {
//         output ~= buf;
//     }
//     return output;
// }


// WEB Based

void threadMain(ubyte n)
{

	// init();
    while(accept)
    {
		writeln("after accept");
    	write("Content-Type: text/html; charset=UTF-8\r\n\r\n");

    	foreach(name, value; request.params) {
            if(name == "SCRIPT_FILENAME"){

                Parser lex = new Parser(); // Create a new object for Parser
                VirtualMachine vm = new VirtualMachine(); // Create a new object for Virtual Machine

                string code; // code file
                code = cast(string) std.file.read(value);

                auto ir = lex.parse(code); // Parsing / Lexing
                vm.execute(ir); // IR to Machine level execution
            }
    	    // writeln(name ~" : " ~ value);
    	}
    	
    	finish;
    }
}

void main() 
{
    for (ubyte i=0; i<8; i++) {
        spawn(&threadMain, i);
    }
}

// Terminal Based

// void main(string[] args)
// {
//     auto helpInformation = getopt(args, config.stopOnFirstNonOption,);
//     string code;

//     if (args.length == 1)
//     {
//         code = readFromStdIn();
//     }
//     else if (helpInformation.helpWanted)
//     {
//         defaultGetoptPrinter("Some information about the program.", helpInformation.options);
//     }
//     else
//     {
//         code = cast(string) std.file.read(args[1]);
//     }
//     Parser lex = new Parser();
//     VirtualMachine vm = new VirtualMachine();

//     auto ir = lex.parse(code);
//     ir.writeln();
//     vm.execute(ir);
// }
