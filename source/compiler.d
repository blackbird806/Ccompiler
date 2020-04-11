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
	
	ASTnode.Type toArithmeticOp()
	{
		switch(type)
		{
			case Type.plus:
				return ASTnode.Type.add;
				
			case Type.minus:
				return ASTnode.Type.substract;
				
			case Type.star:
				return ASTnode.Type.multiply;
				
			case Type.slash:
				return ASTnode.Type.divide;
			default:
			assert(false);
		}
	}

	Type type;
	int value;
}

class Parser
{
	public:

	this(string source)
	{
		this.source = source;
	}

	auto next()
	{
		return source[index++];
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
				next();
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
		debug writeln("start lexing ========");
		while(index < source.length)
		{
			Token tk = scan();
			debug writeln(tk.type);
			tokens ~= tk;
		}
		debug writeln("end lexing ========");
	}

	auto nextToken()
	{
		return tokens[tokenIndex++];
	}

	auto primary()
	{
		auto tk = nextToken();
		ASTnode n;
		switch(tk.type)
		{
			case Token.Type.intLiteral:
				return new ASTnode(ASTnode.Type.intLiteral, tk.value);
			default:
			assert(false);
		}
	}

	auto multiplicativeExpr()
	{
		auto left = primary();
		if (tokenIndex >= tokens.length)
			return left;
		
		while(tokens[tokenIndex].type == Token.type.star || 
			tokens[tokenIndex].type == Token.type.slash)
		{
			auto tk = nextToken();
			auto right = primary();
			left = new ASTnode(tk.toArithmeticOp(), left, right);
			if (tokenIndex >= tokens.length)
				break;
		}
		return left;
	}

	auto additiveExpr()
	{
		auto left = multiplicativeExpr();

		if (tokenIndex >= tokens.length)
			return left;
		
		while(tokenIndex < tokens.length)
		{
			auto tk = nextToken();
			auto right = multiplicativeExpr();
			left = new ASTnode(tk.toArithmeticOp, left, right);
		}

		return left;
	}

	int interpret()
	{
		return interpret(additiveExpr());
	}

	int interpret(ASTnode root)
	{
		int leftValue, rightValue;

		if (root.left !is null)
			leftValue = interpret(root.left);
		if (root.right !is null)
			rightValue = interpret(root.right);

		switch(root.type)
		{
			case ASTnode.Type.add:
				return leftValue + rightValue;
				
			case ASTnode.Type.substract:
				return leftValue - rightValue;
				
			case ASTnode.Type.divide:
				return leftValue / rightValue;
				
			case ASTnode.Type.multiply:
				return leftValue * rightValue;

			case ASTnode.Type.intLiteral:
				return root.value;
			
			default:
				assert(false);
		}
	}

	invariant
	{
		assert(index <= source.length);
	}

	Token[] tokens;
	ASTnode root;
	string source; 
	uint index;
	uint tokenIndex;
	uint line;
}

class ASTnode
{
	public:

	enum Type
	{
		add, substract, multiply, divide, intLiteral
	}

	this(Type type, ASTnode left, ASTnode right, int value = 0)
	{
		this.type = type;
		this.value = value;
		this.left = left;
		this.right = right;
	}

	// unary node
	this(Type type, ASTnode child, int value)
	{
		this.type = type;
		this.value = value;
		this.child = child;
	}

	// make leaf
	this(Type type, int value)
	{
		this.type = type;
		this.value = value;
	}

	ASTnode left;
	ASTnode right;
	alias child = right;
	Type type;
	int value;
}
