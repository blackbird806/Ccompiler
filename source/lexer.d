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
		intLiteral,
		identifier,
		semicolon,
		K_print
	}
	
	Type type;
	int value;
	SourceLocation location;
}

class Lexer
{
	enum keywords = [ "print" : Token.Type.K_print ]; // @suppress(dscanner.performance.enum_array_literal)
	
	this(string code)
	{
		source = code;
	}

	void reportError(Args...)(string fmt, Args args)
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

		switch (c)
		{
			case '+':
				t.type = Token.Type.plus;
				next();
			break;
			case '-':
				t.type = Token.Type.minus;
				next();
			break;
			case '*':
				t.type = Token.Type.star;
				next();
			break;
			case '/':
				t.type = Token.Type.slash;
				next();
			break;
			case '=':
				t.type = Token.Type.equal;
				next();
			break;
			case ';':
				t.type = Token.Type.semicolon;
				if (index == source.length-1) // @suppress(dscanner.suspicious.length_subtraction)
					return Nullable!Token(); 
				next();
			break;

			default:
			if (isNumber(c))
			{
				t.value = scanInt();
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
				else {
					reportError("identifier not supported : \"%s\"", name);
				}
			}
			else if (c.isWhite)
				return Nullable!Token(); // last char is white
			else
				reportError("error bad token");
		}
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