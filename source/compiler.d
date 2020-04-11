module compiler;
import std.stdio;
import std.uni;
import std.conv;

struct Token
{
	enum Type {
		plus,
		minus,
		star,
		slash,
		intLiteral
	}
	
	Type type;
	int value;
}

class Lexer
{
	public:

	this(string source)
	{
		this.source = source;
	}

	auto next()
	{
		return source[++index];
	}

	auto current()
	{
		return source[index];
	}

	auto skip()
	{
		for(char c = current(); c.isWhite; c = next()) { }
		return current();
	}

	auto scanInt()
	{
		auto tmp = index;
        while (index < source.length && source[index].isNumber) { index++; }
		debug write("int:", source[tmp .. index], " ");
        return to!int(source[tmp .. index]);
	}

	auto scan()
	{
		Token t;
		immutable c = skip();
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
			break;

			default:
			if (isNumber(c))
			{
				t.value = scanInt();
				t.type = Token.Type.intLiteral;
				break;
			}

			writeln("error bad token");
		}
		return t;
	}

	void lex()
	{
		while(index < source.length)
		{
			Token tk = scan();
			debug writeln(tk.type);
		}
	}

	invariant
	{
		assert(index <= source.length);
	}

	string source;
	uint index;
	uint line;
}
