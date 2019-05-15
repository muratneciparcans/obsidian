module parser;
import std.string;
import lexer;
import interlang;
import std.conv : to;
import std.stdio;

/// Structure indicating the return value that provides communication between functions.
enum RetType
{
    none,
    expression
}

enum ScopeType
{
    program,
    inline,
    scoped
}

/// The structure in which we keep the priority value to not access over again the transaction priority table
struct Operator
{
    Type type; /// Operator
    size_t precedence; /// Process priority
}

/**
 Our class that will process the code according to the grammatical rules we set.
 */
class Parser : Lexer
{
private:
    Token[] tokens;
    IL il;
    size_t i; // Current Token
    static size_t[Type] op_precedences; /// Transaction Priority table
    static interlang.il[Type] op_ilcodes; /// IL Code representation
    static this()
    {
        // dfmt off
        /**
            The process is shown with a larger number with a high priority.
        */
        op_precedences = [
            Type.lt : 1,
            Type.le : 1,
            Type.ge : 1,
            Type.gt : 1,
            Type.eq : 1,
            Type.neq : 1,

            Type.plus : 2,
            Type.minus : 2,
            Type.times : 3,
            Type.divide : 3
        ];
        op_ilcodes = [
            Type.eq : interlang.il.eq,
            Type.neq : interlang.il.neq,
            Type.lt : interlang.il.lt,
            Type.le : interlang.il.le,
            Type.gt : interlang.il.gt,
            Type.ge : interlang.il.ge,

            Type.plus : interlang.il.add,
            Type.minus : interlang.il.sub,
            Type.times : interlang.il.mul,
            Type.divide : interlang.il.div
        ];
        // dfmt on
    }

public:
    /// Our main function is to send our codes to the lexer and then to start the syntactic analysis.
    IL parse(string code)
    {
        il = new IL();
        tokens = lexit(code); /// Load the tokens to tokens array which are coming from the lexer.
        program();
        il.hlt();
        return il;
    }

private:

    RetType getIt()
    {
        auto ret = getIt2();
        while (i < tokens.length)
        {
            if (getFunction())
            {
            }
            else if (getMethod())
            {
            }
            else if (getSlice())
            {
            }
            else
                break;
        }
        return ret;
    }

    RetType getIt2()
    {
        switch (tokens[i].type)
        {
        case Type.number:
            il.load(to!int(tokens[i].value));
            i++;
            return RetType.expression;
        case Type.string:
            il.load(tokens[i].value);
            i++;
            return RetType.expression;
        case Type._true:
            il.load(true);
            i++;
            return RetType.expression;
        case Type._false:
            il.load(false);
            i++;
            return RetType.expression;
        case Type.identifier:
            string name = tokens[i].value;
            i++;
            if (tokens[i].type == Type.equals)
            {
                i++;
                calcIt();
                il.definevar(name);
            }
            else
            {
                il.loadvar(name);
            }

            return RetType.expression;
        case Type.lparen:
            i++;
            return calcIt(true);
        case Type.lbracket:
            getArray();
            return RetType.expression;
        default:
            return RetType.none;
        }
    }

    RetType getArray()
    {
        expectingLBracket();
        il.newarray();
        while (1)
        {
            if (calcIt() != RetType.none)
            {
                il.apush();
            }
            if (tokens[i].type == Type.rbracket)
            {
                break;
            }
            expectingComma();
        }
        il.astore();
        expectingRBracket();
        return RetType.expression;
    }

    RetType calcIt(bool lparen = false)
    {
        if (calcIt2() == RetType.none)
        {
            return RetType.none;
        }
        size_t[] jzOffsets;
        while (i < tokens.length)
        {
            if (tokens[i].type == Type._and)
            {
                jzOffsets ~= il.jz();
                i++;
                calcIt2();
            }
            else if (tokens[i].type == Type._or)
            {
                jzOffsets ~= il.jnz();
                i++;
                calcIt2();
            }
            else if (lparen && tokens[i].type == Type.rparen)
            {
                lparen = false;
                i++;
                break;
            }
            else
            {
                break;
            }
        }
        if (lparen)
            throw new Exception(
                    "Expecting closure of parentheses - %s did not expected".format(tokens[i].type));

        foreach (jzOffset; jzOffsets)
        {
            il.load(il.pos, jzOffset);
        }
        return RetType.expression;
    }

    /**
        A function that separates mathematical expressions according to process priority using the Shunting-Yard algorithm.
    */
    RetType calcIt2()
    {
        Operator[] operators; /// Operator stack where operators are temporarily stored
        int waitexp = 0; /// to check for mathematical expression
        while (i < tokens.length)
        {
            if (getIt() == RetType.expression) {
                // op_precedences.writeln();
                waitexp = 1; /// We're reading our first statement
            }
            else if (auto p = tokens[i].type in op_precedences)
            { /// get process priority from the priority table
                while (operators.length > 0 && *p <= operators[$ - 1].precedence)
                { /// If the operator has a stack element and the process priority is smaller
                    il.newcode(op_ilcodes[operators[$ - 1].type]);
                    operators = operators[0 .. $ - 1]; /// Delete operator from the stack.
                }
                il.push();
                operators ~= Operator(tokens[i].type, *p); /// Add operator to Stack
                
                i++;
                waitexp = 2; /// Now that an operator is coming, an expression will have to come.
            }
            else if (waitexp == 1)
                break; /// first if expression does not appear in the first statement and if it's expecting an expression then break the loop.
            else
                break;
        }
        if (waitexp == 0)
            return RetType.none;
        if (waitexp == 2)
            throw new Exception("An expression was expected but %s got".format(tokens[i].type));
        foreach_reverse (operator; operators)
        { /// Process all remaining operators in operator stack.
            il.newcode(op_ilcodes[operator.type]);
        }
        return RetType.expression;
    }

    bool getMethod()
    {
        if (tokens[i].type == Type.dot)
            i++;
        else
            return false;
        if (tokens[i].type == Type.identifier)
        {
            il.getProperty(tokens[i].value);
            i++;
            return true;
        }
        else
        {
            expectedError("Identifier");
            assert(0);
        }
    }

    bool getSlice()
    {
        if (tokens[i].type == Type.lbracket)
            i++;
        else
            return false;
        il.push();
        calcIt();
        expectingRBracket();
        if (i < tokens.length && tokens[i].type == Type.equals)
        {
            i++;
            il.push();
            calcIt();
            il.opIndexAssign();
        }
        else
        {
            il.opIndex();

        }
        return true;
    }

    /**
        Captures function calls.
    */
    bool getFunction()
    {
        size_t pcount;
        if (tokens[i].type == Type.lparen)
            i++; /// If you have token ( if not then it will exit from function calling.
        else
            return false;
        il.push();
        if (tokens[i].type == Type.rparen)
            goto end; /// If the parentheses are closed, they jump to the end without going through the loop.
        while (i < tokens.length)
        {
            if (calcIt() == RetType.none)
            {
                throw new Exception("while expecting for an expression, we got %s".format(tokens[i].type));
            }
            else
            {
                pcount++;
                il.pushparam();
            }
            if (tokens[i].type == Type.comma)
            { /// Check the 'comma' for the next parameter.
                i++;
                continue;
            }
            else
                break;
        }
        if (i >= tokens.length)
            throw new Exception("Parenthesis expected to be closed.");
        else if (tokens[i].type != Type.rparen)
            throw new Exception(
                    "Parenthesis expected to be closed but we've got %s".format(tokens[i].type));
    end:
        i++;
        il.call(pcount);
        return true;
    }

    bool getWhile()
    {
        if (tokens[i].type == Type._while)
            i++;
        else
            return false;
        expectingLParen();
        size_t condition_pos = il.pos();
        if (calcIt() == RetType.none)
        {
            throw new Exception("While expecting for an expression we'v got %s".format(tokens[i].type));
        }
        expectingRParen();
        auto jzOffset = il.jz();
        program(ScopeType.inline);
        il.jmp(condition_pos);
        il.load(il.pos, jzOffset);
        return true;
    }

    bool getIf()
    {
        if (tokens[i].type == Type._if)
            i++;
        else
            return false;
        expectingLParen();
        if (calcIt() == RetType.none)
        {
            throw new Exception("While expecting for an expression we'v got %s".format(tokens[i].type));
        }
        expectingRParen();
        auto jzOffset = il.jz();
        program(ScopeType.inline);
        if (i < tokens.length && tokens[i].type == Type._else)
        {
            i++;
            auto jmpOffset = il.jmp();
            il.load(il.pos, jzOffset);
            program(ScopeType.inline);
            il.load(il.pos, jmpOffset);
        }
        else
        {
            il.load(il.pos, jzOffset);
        }
        return true;
    }

    void program(ScopeType scoped = ScopeType.program)
    {
        if (scoped == ScopeType.scoped)
            expectingLCurly();
        while (i < tokens.length) /// While token exist
        {
            const type = tokens[i].type;
            if (getWhile()) {}
            else if (getIf()) {}
            else if (type == Type.lcurly)
                program(ScopeType.scoped);
            else if (type == Type.rcurly && scoped == ScopeType.scoped)
            {
                i++;
                return;
            }
            else if (calcIt() != RetType.none)
            {
                expectingSemicolon(true);
            }
            else
            {
                throw new Exception("Unexpected type: %s".format(tokens[i].type));
            }
            if (scoped == ScopeType.inline)
                return;
        }
        if (scoped == ScopeType.scoped)
            expectedError("Closing the scope");

    }

    void expectedError(string expected)
    {
        if (i < tokens.length)
        {
            throw new Exception("%s expected but %s got".format(expected, tokens[i].type));
        }
        else
        {
            throw new Exception("%s expected".format(expected));
        }
    }

    void expectingLParen()
    {
        if (tokens[i].type == Type.lparen)
            i++;
        else
            throw new Exception("While waiting for an parentheses, %s got".format(tokens[i].type));
    }

    void expectingRParen()
    {
        if (i >= tokens.length)
            throw new Exception("The parenthesis was expected to close.");
        else if (tokens[i].type == Type.rparen)
            i++;
        else
            throw new Exception(
                    "While waiting for an parentheses, %s got".format(tokens[i].type));
    }

    void expectingLCurly()
    {
        if (i >= tokens.length)
            throw new Exception("Curly braces was expected");
        else if (tokens[i].type == Type.lcurly)
            i++;
        else
            throw new Exception("Curly braces was expected but %s got".format(tokens[i].type));
    }

    void expectingLBracket()
    {
        if (i >= tokens.length)
            throw new Exception("[ was expected.");
        else if (tokens[i].type == Type.lbracket)
            i++;
        else
            throw new Exception("[ was expected. but %s got".format(tokens[i].type));
    }

    void expectingComma()
    {
        if (i >= tokens.length)
            throw new Exception(", was expected.");
        else if (tokens[i].type == Type.comma)
            i++;
        else
            throw new Exception(", was expected. but %s got".format(tokens[i].type));
    }

    void expectingRBracket()
    {
        if (i >= tokens.length)
            throw new Exception("] was expected.");
        else if (tokens[i].type == Type.rbracket)
            i++;
        else
            throw new Exception("] was expected. but %s got".format(tokens[i].type));
    }

    void expectingRCurly()
    {
        if (i >= tokens.length)
            throw new Exception("Curly braces were expected to close.");
        else if (tokens[i].type == Type.rcurly)
            i++;
        else
            throw new Exception(
                    "Curly braces were expected to close. but %s got".format(
                    tokens[i].type));
    }

    void expectingSemicolon(bool required)
    {
        if (required && i >= tokens.length)
            throw new Exception("; was expected.");
        else if (i < tokens.length && tokens[i].type == Type.semicolon)
            i++;
        else if (required)
            throw new Exception("; was expected. but %s got".format(tokens[i].type));
    }
}
