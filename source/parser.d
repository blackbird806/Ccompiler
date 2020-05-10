module parser;

import lexer;

void reportError(Args...)(string fmt, Args args)
{
	import std.stdio : writefln;
	writefln("[parser] error : " ~ fmt, args);
}

class ASTnode
{
	
}

class BinExpr : ASTnode
{
	enum Type
	{
		add, substract, multiply, divide, nullOP
	}

	static Type toBinExprType(Token.Type tktype)
	{
		enum opTypes = [ // @suppress(dscanner.performance.enum_array_literal)
			Token.Type.plus 	: Type.add,
			Token.Type.minus 	: Type.substract,
			Token.Type.star 	: Type.multiply,
			Token.Type.slash 	: Type.divide,
		];

		Type* t = tktype in opTypes;

		if (!t)
		{
			reportError("bad tk type for binExpr : %s", tktype);
			return Type.nullOP;
		}

		return *t;
	}

	this(ASTnode l, ASTnode r, Type t)
	{
		left = l;
		right = r;
		opType = t;
	}

	Type opType;
	ASTnode left, right;
}

class IntLiteral : ASTnode
{
	this(int v)
	{
		value = v;
	}

	int value;
}

class Parser
{
	this(Token[] tks)
	{
		tokens = tks;
		entryPoint = new BinExpr(
			new BinExpr(
				new IntLiteral(5),
				new IntLiteral(2),
				BinExpr.Type.multiply
			),
			new IntLiteral(12),
			BinExpr.Type.add
		);
	}

	invariant
	{
		assert(index < tokens.length);
	}

	ASTnode entryPoint;
	uint index = 0;
	Token[] tokens;
}