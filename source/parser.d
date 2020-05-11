module parser;

import std.stdio : writefln, writeln;
import lexer;

void reportError(Args...)(string fmt, Args args)
{
	writefln("[parser] error : " ~ fmt, args);
}

// automaticly generate specialized visit method for each child of ASTNode
string genVisitMethods()
{
	import std.traits;
	
	string codeGen;
	static foreach(memStr; __traits(allMembers, parser))
	{
		static if (isType!(mixin(memStr)) &&
		!__traits(isSame, mixin(memStr), ASTnode) && 
		isImplicitlyConvertible!(mixin(memStr), ASTnode))
		{
			codeGen ~= q{void visit(} ~ memStr ~ q{);};
		}
	}

	return codeGen;
}

interface ASTvisitor
{
	mixin(genVisitMethods());
}

abstract class ASTnode
{
	void accept(ASTvisitor);
}

mixin template implementVisitor()
{
	override void accept(ASTvisitor v)
	{
		v.visit(this);
	}
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
			reportError("bad token type for binExpr : %s", tktype);
			return Type.nullOP;
		}

		return *t;
	}

	mixin implementVisitor;

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
	mixin implementVisitor;

	this(int v)
	{
		value = v;
	}

	int value;
}

class PrintKeyword : ASTnode
{
	mixin implementVisitor;

	this(ASTnode c)
	{
		child = c;
	}

	ASTnode child;
}

enum operatorPrecedence = [	 // @suppress(dscanner.performance.enum_array_literal)
							BinExpr.Type.add: 1, 
							BinExpr.Type.substract: 1,
							BinExpr.Type.multiply: 2,
							BinExpr.Type.divide: 2 
						];


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

	uint opPrecedence(Token tk)
	{
		BinExpr.Type t = BinExpr.toBinExprType(tk.type);
		if (t !in operatorPrecedence)
		{
			reportError("syntax error token : %s", tk);
			assert(false);
		}
		return operatorPrecedence[t];
	}

	Token nextToken()
	{
		return tokens[index++];
	}

	ASTnode primary()
	{
		Token tk = nextToken();
		ASTnode n;
		switch(tk.type)
		{
			case Token.Type.intLiteral:
				return new IntLiteral(tk.value);
			default:
				reportError("bad primary token %s", tk.type);
				assert(false);
		}
	}

	ASTnode binExpr(int lastPred)
	{
		ASTnode left = primary();

		if (tokens[index].type == Token.Type.semicolon)
			return left;

		while(opPrecedence(tokens[index]) > lastPred)
		{
			Token tk = nextToken();
			BinExpr.Type opType = BinExpr.toBinExprType(tk.type);
			ASTnode right = binExpr(operatorPrecedence[opType]);
			left = new BinExpr(left, right, opType);

			if (tokens[index].type == Token.Type.semicolon)
				return left;
		}

		return left;
	}

	ASTnode multiplicativeExpr()
	{
		ASTnode left = primary();
		if (index >= tokens.length)
			return left;
		
		while(	tokens[index].type == Token.type.star || 
				tokens[index].type == Token.type.slash)
		{
			Token tk = nextToken();
			ASTnode right = primary();
			left = new BinExpr(left, right, BinExpr.toBinExprType(tk.type));
			if (index >= tokens.length)
				break;
		}
		return left;
	}

	ASTnode additiveExpr()
	{
		ASTnode left = multiplicativeExpr();

		if (index >= tokens.length)
			return left;
		
		while(index < tokens.length)
		{
			Token tk = nextToken();
			ASTnode right = multiplicativeExpr();
			left = new BinExpr(left, right, BinExpr.toBinExprType(tk.type));
		}

		return left;
	}

	void parse()
	{
		if (tokens[0].type == Token.Type.K_print)
		{
			entryPoint = new PrintKeyword(binExpr(0));
		}
		else
			entryPoint = binExpr(0);
	}

	void printAST()
	{
		printAST(entryPoint);
	}

	void printAST(ASTnode node)
	{
		class ASTprinter : ASTvisitor
		{
			override void visit(BinExpr binNode)
			{
				if (binNode.left)
					binNode.left.accept(this);
				if (binNode.right)
					binNode.right.accept(this);

				writefln("left %s \t op %s \t right %s \n", binNode.left, binNode.right, binNode.opType);
			}

			override void visit(IntLiteral intNode)
			{
				writefln("int value : %d", intNode.value);
			}

			override void visit(PrintKeyword printNode)
			{
				writefln("print");
				printNode.child.accept(this);
			}
		}

		auto printer = new ASTprinter();
		entryPoint.accept(printer);
	}

	invariant
	{
		assert(index <= tokens.length);
	}

	ASTnode entryPoint;
	uint index = 0;
	Token[] tokens;
}