import fcgi.stdio;
import parser;
import obsobject;
import vm;
import std.file;
import std.getopt;
import std.concurrency;


string readFromStdIn()
 {
    import std.stdio : stdin;

    string output;
     char[] buf;

    while (stdin.readln(buf))
     {
        output ~= buf;
     }
     return output;
 }


/* Both execution modes drive the same parser and virtual machine; only the
   surrounding I/O differs. Build the web one with:

       dub build --config=fcgi
*/
version (fcgi)
{
    // WEB Based

    void threadMain(ubyte n)
    {
        while(accept)
        {
            write("Content-Type: text/html; charset=UTF-8\r\n\r\n");

            foreach(name, value; request.params) {
                if(name == "SCRIPT_FILENAME") {

                    Parser lex = new Parser(); // Create a new object for Parser
                    VirtualMachine vm = new VirtualMachine(); // Create a new object for Virtual Machine

                    try
                    {
                        string code; // code file
                        code = cast(string) std.file.read(value);

                        auto ir = lex.parse(code); // Parsing / Lexing
                        vm.execute(ir); // IR to Machine level execution
                    }
                    catch (Exception error)
                    {
                        /* A failing script must not take the whole
                           persistent process down with it. */
                        write("Hata: " ~ error.msg ~ "\n");
                    }
                }
            }

            finish;
        }
    }

    void main()
    {
        init();
        for (ubyte i = 0; i < 8; i++)
        {
            spawn(&threadMain, i);
        }
    }
}
else
{
    // Terminal Based

    int main(string[] args) {
        import std.stdio : stderr;

        auto helpInformation = getopt(args, config.stopOnFirstNonOption);
        string code;

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter("Usage: language [script.obs]", helpInformation.options);
            return 0;
        }
        else if (args.length == 1)
        {
            code = readFromStdIn();
        }
        else
        {
            code = cast(string) std.file.read(args[1]);
        }
        Parser lex = new Parser();
        VirtualMachine vm = new VirtualMachine();

        /* Lexer, parser and runtime all report problems as exceptions, so the
           driver turns them into one readable line instead of a stack trace. */
        try
        {
            auto ir = lex.parse(code);
            vm.execute(ir);
        }
        catch (Exception error)
        {
            stderr.writeln("Hata: ", error.msg);
            return 1;
        }
        return 0;
    }
}
