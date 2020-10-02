module lexer;
import std.stdio : writefln, writeln, write;
import std.uni;
import std.array;
import std.algorithm;
import std.conv : to;
import std.typecons : Nullable;

struct SourceLocation
{
	uint lineNum;

	string toString() const @safe
	{
		import std.format : format;
		return format!"line %s"(lineNum);
	}
}

struct Token
{
	enum Type {

		plus,
		minus,
		star,
		slash,
		equal,

		equalEqual,
		notEqual,
		less,
		greater,
		lessEqual,
		greaterEqual,

		intLiteral,

		identifier,

		semicolon,
		openBrace,
		closedBrace,
		openParenthesis,
		closedParenthesis,

		K_print,
		
		K_int,
		K_long,
		K_void,
		K_char,

		K_if,
		K_else,
		K_while,
		K_for,
		K_return,

		invalid,
	}
	
	Type type;
	SourceLocation location;
	
	union
	{
		int intValue;
		string identifierName;
	}
}

struct MacroExpand
{
	string expandedStr;
	string[] parameterNames;

	string getExpandedMacroWithArgs(string[] parameters) const
	{
		if (parameters.length != parameterNames.length)
			writeln("[preprocessor error] parameters count do not match with macro declaration !");

		string result;

		foreach (i, string param; parameterNames)
		{
			result = expandedStr.replace(param, parameters[i]);
		}

		return result;
	}
}

class Lexer
{
	enum keywords = [ 	"print" 	: Token.Type.K_print,
						"long" 		: Token.Type.K_long,
						"int" 		: Token.Type.K_int,
						"void" 		: Token.Type.K_void,
						"char" 		: Token.Type.K_char,
						"if" 		: Token.Type.K_if,
						"else" 		: Token.Type.K_else,
						"while" 	: Token.Type.K_while,
						"for" 		: Token.Type.K_for,
						"return" 	: Token.Type.K_return,
						];

	this(string code)
	{
		source = code;
		source ~= " "; // quickfix to avoid out of range error when lexing
	}

	private void reportError(Args...)(string fmt, Args args)
	{
		writefln("[Lexer] Error line %d: " ~  fmt, lineCount, args);
		debug(FatalError) assert(0);
	}

	char current()
	{
		return source[index];
	}

	char peek(int n)
	in (n + index < source.length && n + index > 0)
	{
		return source[index + n];
	}

	char next()
	{
		return source[++index];
	}

	// skip all blank characters on the current line
	char skipBlankOnLine()
	{
		for(char c = current(); c.isWhite() && c != '\n' && index + 1  < source.length; c = next()) {
		}
		return current();
	}

	char skipBlank()
	{
		for(char c = current(); c.isWhite() && index  + 1 < source.length; c = next()) { 
			if (c == '\n')
				lineCount++;
		}

		return current();
	}

	void skipLine()
	{
		for(char c = current(); c != '\n' && index < source.length-1; c = next()) // @suppress(dscanner.suspicious.length_subtraction)
			{	}
		lineCount++;
	}

	string lineStr()
	{
		string line;
		for(char c = current(); c != '\n' && index < source.length-1; c = next()) // @suppress(dscanner.suspicious.length_subtraction)
		{
			line ~= c;
		}
		lineCount++;
		return line;
	}

	string peekLineStr()
	{
		const tmp = index;
		string line;
		for(char c = current(); c != '\n' && index < source.length-1; c = next()) // @suppress(dscanner.suspicious.length_subtraction)
		{
			line ~= c;
		}
		index = tmp;
		return line;
	}

	int scanInt()
	{
		uint tmp = index;
        while (index < source.length && current().isNumber) 
		{ 
			index++; 
		}
        return to!int(source[tmp .. index]);
	}

	string scanIdent()
	{
		char c = current();
		immutable uint start = index;
		while((c.isAlphaNum() || c == '_') && index < source.length)
		{
			c = next();	
		}

		return source[start .. index];
	}

	// TODO check how to handle C preprocessor elegantly
	void preprocessorPass()
	{
		while (index + 1 < source.length)
		{
			char c = skipBlank();
			if (c == '/')
			{
				if (peek(1) == '/') { // single line comment
					next();
					skipLine();
				}
				else
				{
					next();
				}
			}
			else if (c == '#')
			{
				next();
				string directive = scanIdent();
				string[] parameterNames;

				if (directive == "define")
				{
					skipBlankOnLine();
					const string macroName = scanIdent();
					skipBlankOnLine();

					if (current() == '(')
					{
						next();
						parameterNames = peekLineStr().split(")").front().split(",");
					}
					while (next() != ')') { }
					next();

					skipBlankOnLine();
					
					string macroExpand = "";
					if (current() != '\n')
						macroExpand = lineStr();

					defineSets[macroName] = MacroExpand(macroExpand, parameterNames);
				}
				else
				{
					reportError("undefined preprocessor directive");
				}
			}
			else if (isAlpha(c) || c == '_')
			{
				uint identStart = index;
				string ident = scanIdent();
				if (ident in defineSets)
				{
					if (defineSets[ident].parameterNames == null) // if no parameters no need for parentheses
					{
						source.replaceInPlace(identStart, index, defineSets[ident].expandedStr);
					}
					else
					{
						import std.conv : to;

						uint numParenthesis = 0;
						bool parenthesisMatch(CharT)(CharT p)
						{
							if (p == '(')
								numParenthesis++;
							else if (p == ')')
								numParenthesis--;
								
							return numParenthesis == 0;
						}

						string[] params = peekLineStr().filter!(a => !a.isWhite() && !parenthesisMatch(a)).array.to!string.split(")").front().split(",");
						while (next() != ')') { }
						source.replaceInPlace(identStart, index+1, defineSets[ident].getExpandedMacroWithArgs(params));
					}
				}
			}
			else
			{
				if (index + 1 == source.length)
					break;
				next();
			}
		}

		index = 0;
	}

	/*
		scan next unread token 
		returning null mean end of code
	*/
	Nullable!Token scan()
	{
		l_rescan:

		Token t;
		immutable char c = skipBlank();
		with (Token.Type) {
		switch (c)
		{
			case '+':
				t.type = plus;
				next();
			break;
			case '-':
				t.type = minus;
				next();
			break;
			case '*':
				t.type = star;
				next();
			break;
			case '/':
				if (peek(1) == '/') { // single line comment
					next();
					skipLine();
					goto l_rescan; // get next token after line comment
				}
				t.type = slash;
				next();
			break;
			case '(':
				t.type = openParenthesis;
				next();
			break;
			case ')':
				t.type = closedParenthesis;
				next();
			break;
			case '{':
				t.type = openBrace;
				next();
			break;
			case '}':
				t.type = closedBrace;
				next();
			break;
			case '=':
				if (peek(1) == '=')
				{
					next();
					t.type = equalEqual;
				}
				else
					t.type = equal;
				next();
			break;
			case '<':
				if (peek(1) == '=')
				{
					next();
					t.type = lessEqual;
				}
				else
					t.type = less;
				next();
			break;
			case '>':
				if (peek(1) == '=')
				{
					next();
					t.type = greaterEqual;
				}
				else
					t.type = greater;
				next();
			break;
			case '!':
				if (peek(1) == '=') {
					next();
					t.type = notEqual;
				}
				else
					reportError("char '!' is not a valid token");
				next();
			break;
			case '#':
				skipLine();
				goto l_rescan;
			case ';':
				t.type = semicolon;
				if (index == source.length-1) // @suppress(dscanner.suspicious.length_subtraction)
					return Nullable!Token(); 
				next();
			break;

			default:
			if (isNumber(c))
			{
				t.intValue = scanInt();
				t.type = Token.Type.intLiteral;
			}
			else if (isAlpha(c) || c == '_')
			{
				string name = scanIdent();
				Token.Type* ktype = name in keywords;
				if (ktype)
				{
					t.type = *ktype;
				}
				else // identifier 
				{
					t.type = Token.Type.identifier;
					t.identifierName = name;
				}
			}
			else if (c.isWhite())
				return Nullable!Token(); // last char is white
			else
				reportError("bad token index[%s] char : '%s'", index, c);
		} // switch
		} // with(Token)
		t.location = SourceLocation(lineCount);
		return Nullable!Token(t);
	}

	Token[] lex()
	in(index == 0)	// ensure lex is called only once
	{
		Nullable!Token tk = scan();
		while(!tk.isNull)
		{
			tokens ~= tk;
			tk = scan();
		}
		return tokens;
	}

	invariant
	{
		assert(index <= source.length);
		assert(source.length > 0);
	}

	string source;
	uint index = 0;
	uint lineCount = 0;
	Token[] tokens;

	// preprocessor
	MacroExpand[string] defineSets;
}
