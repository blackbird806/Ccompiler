module lexer;
import std.stdio : writefln, writeln, write;
import std.uni;
import std.conv : to;
import std.typecons : Nullable;

struct SourceLocation
{
	uint lineNum;
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
		K_if,
		K_else,

		invalid,
	}
	
	Type type;
	SourceLocation location;
	
	union 
	{
		int value_int;
		string identifier_name;
	}
}

class Lexer
{
	enum keywords = [ 	"print" : Token.Type.K_print, // @suppress(dscanner.performance.enum_array_literal)
						"int" 	: Token.Type.K_int,
						"if" 	: Token.Type.K_if,
						"else" 	: Token.Type.K_else,
						]; 
	
	this(string code)
	{
		source = code;
	}

	private void reportError(Args...)(string fmt, Args args)
	{
		writefln("[Lexer] Error line %d: " ~  fmt, lineCount, args);
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

	char skip()
	{
		for(char c = current(); c.isWhite && index < source.length-1; c = next()) { // @suppress(dscanner.suspicious.length_subtraction)
			debug writefln("skip index %d", index);
			if (c == '\n')
				lineCount++;
		}

		return current();
	}

	void skipLine()
	{
		for(char c = current(); c != '\n' && index < source.length-1; c = next()) // @suppress(dscanner.suspicious.length_subtraction)
			{}
		lineCount++;
	}

	int scanInt()
	{
		uint tmp = index;
        while (index < source.length && current().isNumber) { index++; }
		// debug writeln("int:", source[tmp .. index], " ");
        return to!int(source[tmp .. index]);
	}

	string scanIdent()
	{
		char c = current();
		uint start = index;
		while((c.isAlphaNum || c == '_') && index < source.length)
		{
			c = next();	
		}

		return source[start .. index];
	}

	Nullable!Token scan()
	{
		Token t;

		immutable char c = skip();
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
				if (next() == '/') { // single line comment
					skipLine();
					break;
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
				if (next() == '=')
					t.type = equalEqual;
				else
					t.type = equal;
				next();
			break;
			case '<':
				if (next() == '=')
					t.type = lessEqual;
				else
					t.type = less;
				next();
			break;
			case '>':
				if (next() == '=')
					t.type = greaterEqual;
				else
					t.type = greater;
				next();
			break;
			case '!':
				if (next() == '=') {
					t.type = notEqual;
					next();
				}
				else
					reportError("char '!' is not a valid token");
			break;
			case ';':
				t.type = semicolon;
				if (index == source.length-1) // @suppress(dscanner.suspicious.length_subtraction)
					return Nullable!Token(); 
				next();
			break;

			default:
			if (isNumber(c))
			{
				t.value_int = scanInt();
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
					t.identifier_name = name;
				}
			}
			else if (c.isWhite)
				return Nullable!Token(); // last char is white
			else
				reportError("error bad token");
		} // switch
		} // with(Token)
		t.location = SourceLocation(lineCount);
		return Nullable!Token(t);
	}

	Token[] lex()
	in(index == 0)	// ensure lex is called only once
	{
		Nullable!Token tk = scan();
		debug writeln(tk);
		while(!tk.isNull)
		{
			tokens ~= tk;
			tk = scan();
			debug writeln(tk);
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
}
