module lexer;
import std.ascii;
import std.string;

enum Type{
	nope, identifier, number, string, _true, _false,

	//Operators (+,-,*,/,=)
	plus, minus, times, divide, equals,

	lparen, rparen, comma,

	eq, lt, le, gt, ge, neq,

	lcurly, rcurly,
	lbracket, rbracket,
	_while, _if, _else,

	_and, _or, dot,

	semicolon
}

struct Token{
	Type type;
	string value;
}

class Lexer{

    Type[string] keywords;

    this(){
        keywords = [
            "true": Type._true,
            "false": Type._false,
            "while": Type._while,
            "if": Type._if,
            "else": Type._else,
            "and": Type._and,
            "or": Type._or,
        ];
    }

	Token[] lexit(string code){
		Token[] tokens;
		auto cp = code.ptr;
		const end = code.ptr + code.length;
		while(cp < end){
			if(isWhite(*cp)){
				cp++;
			}else if(isAlpha(*cp) || *cp == '_'){
				/* As long as there are letters and numbers, we place them in an array. */
				string tmp;
				do{
					tmp ~= *cp;
					cp++;
				} while(cp < end && (isAlphaNum(*cp) || *cp == '_'));
				// If the word is a keyword, it will consider and record it as a keyword instead of a variable.
				if(auto k = tmp in keywords) tokens ~= Token(*k, tmp);
				else tokens ~= Token(Type.identifier, tmp);
			}else if(isDigit(*cp)){
				// We're catching the numbers.
				string tmp;
				do{
					tmp ~= *cp;
					cp++;
				} while(cp < end && isDigit(*cp));
				tokens ~= Token(Type.number, tmp);
			}else if(*cp == '\"'){
				// We get a string in the form of "text".
				string tmp;
				cp++;
				do{
					tmp ~= *cp;
					cp++;
				} while(cp < end && *cp!='\"'); // We put all the characters until the quotation marks come in.
					cp++;
					tokens ~= Token(Type.string, tmp);
			}else if(*cp == '.'){
				tokens ~= Token(Type.dot);
				cp++;
			}else if(*cp == '+'){
				tokens ~= Token(Type.plus);
				cp++;
			}else if(*cp == '{'){
				tokens ~= Token(Type.lcurly);
				cp++;
			}else if(*cp == '}'){
				tokens ~= Token(Type.rcurly);
				cp++;
			}else if(*cp == '-'){
				tokens ~= Token(Type.minus);
				cp++;
			}else if(*cp == '*'){
				tokens ~= Token(Type.times);
				cp++;
			}else if(*cp == '/'){
				cp++;
				/* "//" Ignore comment lines. */
				if(*cp == '/'){
					while(cp < end && *cp != '\n'){
						cp++;
					}
					cp++;
				}else tokens ~= Token(Type.divide);
			}else if(*cp == '='){
				cp++;
				if(cp < end && *cp == '='){
				    cp++;
    				tokens ~= Token(Type.eq);
				}else{
                    tokens ~= Token(Type.equals);
				}
			}else if(*cp == '!' && *(cp + 1) == '='){
                tokens ~= Token(Type.neq);
                cp+=2;
			}else if(*cp == '<' && *(cp + 1) == '='){
                tokens ~= Token(Type.le);
                cp+=2;
			}else if(*cp == '<'){
                tokens ~= Token(Type.lt);
                cp++;
			}else if(*cp == '>' && *(cp + 1) == '='){
                tokens ~= Token(Type.ge);
                cp+=2;
			}else if(*cp == '>'){
                tokens ~= Token(Type.gt);
                cp++;
			}else if(*cp == ';'){
				tokens ~= Token(Type.semicolon);
				cp++;
			}else if(*cp == '['){
				tokens ~= Token(Type.lbracket);
				cp++;
			}else if(*cp == ']'){
				tokens ~= Token(Type.rbracket);
				cp++;
			}else if(*cp == '('){
				tokens ~= Token(Type.lparen);
				cp++;
			}else if(*cp == ')'){
				tokens ~= Token(Type.rparen);
				cp++;
			}else if(*cp == ','){
				tokens ~= Token(Type.comma);
				cp++;
			}else{
				throw new Exception("Unexpected character: %s".format(*cp));
			}
		}
		return tokens;
	}
}