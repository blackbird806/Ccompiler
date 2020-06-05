module parser;

import std.stdio;
import lexer;

private void reportError(Args...)(string fmt, Args args)
{
	writefln("[parser] error " ~ fmt, args);
}

// automaticly generate specialized visit method for each child of ASTNode
string genVisitMethods()
{
	import std.traits; // @suppress(dscanner.suspicious.local_imports)
	
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

mixin template implementVisitor()
{
	override void accept(ASTvisitor v)
	{
		v.visit(this);
	}
}

interface ASTvisitor
{
	mixin(genVisitMethods());
}

abstract class ASTnode
{
	void accept(ASTvisitor);
}

class BinExpr : ASTnode
{
	enum Type
	{
		add, substract, multiply, divide,  // arithmetic
		equal, notEqual, less, greater, lessEqual, greaterEqual, // comparison
		nullOP
	}

	static Type toBinExprType(Token.Type tktype)
	{
		enum opTypes = [ // @suppress(dscanner.performance.enum_array_literal)
			Token.Type.plus 			: Type.add,
			Token.Type.minus 			: Type.substract,
			Token.Type.star 			: Type.multiply,
			Token.Type.slash 			: Type.divide,

			Token.Type.equalEqual 		: Type.equal,
			Token.Type.less 			: Type.less,
			Token.Type.greater 			: Type.greater,
			Token.Type.greaterEqual 	: Type.greaterEqual,
			Token.Type.lessEqual 		: Type.lessEqual,
			Token.Type.notEqual 		: Type.notEqual,
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

class VarDecl : ASTnode
{
	mixin implementVisitor;

	this(Variable.Type t, string name)
	{
		type = t;
		varName = name;
	}

	Variable.Type type;
	string varName;
}

class AssignStatement : ASTnode
{
	mixin implementVisitor;

	this(Variable v, ASTnode r)
	{
		var = v;
		right = r;
	}

	Variable var;
	ASTnode right;
}

class Variable : ASTnode
{
	enum Type {
		int_
	}

	mixin implementVisitor;

	this(string varName, Type t)
	{
		name = varName;
		type = t;
	}

	string name;
	Type type;
}

class IfStatement : ASTnode
{
	mixin implementVisitor;

	this(ASTnode c, ASTnode i, ASTnode e)
	{
		condition = c;
		ifBody = i;
		elseBody = e;
	}

	ASTnode condition, ifBody, elseBody;
}

class Glue : ASTnode
{
	mixin implementVisitor;

	this(ASTnode t, ASTnode l)
	{
		tree = t;
		left = l;
	}

	ASTnode tree, left;
}

enum operatorPrecedence = [	 // @suppress(dscanner.performance.enum_array_literal)
							BinExpr.Type.add: 1, 
							BinExpr.Type.substract: 1,
							BinExpr.Type.multiply: 2,
							BinExpr.Type.divide: 2,

							BinExpr.Type.equal: 3,
							BinExpr.Type.notEqual: 3,

							BinExpr.Type.less: 4,
							BinExpr.Type.lessEqual: 4,
							BinExpr.Type.greater: 4,
							BinExpr.Type.greaterEqual: 4,
						];


class Parser
{
	this(Token[] tks)
	{
		tokens = tks;
	}

	uint opPrecedence(Token tk)
	{
		BinExpr.Type t = BinExpr.toBinExprType(tk.type);
		if (t !in operatorPrecedence)
		{
			reportError("line %d : syntax error token : %s", tk.location.lineNum, tk.type);
			assert(false);
		}
		return operatorPrecedence[t];
	}

	Token nextToken()
	{
		return tokens[index++];
	}

	Token peekToken()
	{
		if (index + 1 >= tokens.length)
		{
			Token t;
			// @Review TokenType EOF ?
			t.type = Token.Type.invalid;
			return t;
		}
		return tokens[index+1];
	}

	ASTnode primary()
	{
		Token tk = nextToken();
		switch(tk.type)
		{
			case Token.Type.intLiteral:
				return new IntLiteral(tk.value_int);
			case Token.Type.identifier:
				if (!(tk.identifier_name in symTable))
				{
					reportError("line %d : undefined identifier : %s", tk.location.lineNum, tk.identifier_name);
				}
				return new Variable(tk.identifier_name, Variable.Type.int_);
			default:
				reportError("line %d : bad primary token %s", tk.location.lineNum, tk.type);
				assert(false);
		}
	}

	ASTnode binExpr(int lastPred)
	{
		ASTnode left = primary();

		if (tokens[index].type == Token.Type.semicolon || tokens[index].type == Token.Type.closedParenthesis)
			return left;

		while(opPrecedence(tokens[index]) > lastPred)
		{
			Token tk = nextToken();
			BinExpr.Type opType = BinExpr.toBinExprType(tk.type);
			ASTnode right = binExpr(operatorPrecedence[opType]);
			left = new BinExpr(left, right, opType);

			if (tokens[index].type == Token.Type.semicolon || tokens[index].type == Token.Type.closedParenthesis)
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

	// ensure next token is of type "type"
	// return result of nextToken()
	Token expect(Token.Type type)
	{
		Token n = nextToken();
		if (n.type != type)
			reportError("line %d : %s token expected instead of %s", n.location.lineNum, type, n.type);
		return n;
	}

	ASTnode varDecl(Token n)
	in(n.type == Token.Type.K_int) // only int are supported currently
	{
		Token varidentTk = expect(Token.Type.identifier);
		bool symbolExist = true;

		// https://dlang.org/spec/hash-map.html#inserting_if_not_present
		Variable newSym = symTable.require(varidentTk.identifier_name, 
		{
			symbolExist = false;
			return new Variable(varidentTk.identifier_name, Variable.Type.int_);
		}());
		
		if (symbolExist)
		{
			reportError("line %d : symbol \"%s\" already defined", varidentTk.location.lineNum, varidentTk.identifier_name);
		}

		return new VarDecl(Variable.Type.int_, varidentTk.identifier_name);
	}

	ASTnode assignementStatement(Token identTk)
	in(identTk.type == Token.Type.identifier)
	{
		expect(Token.Type.equal);
		ASTnode right = binExpr(0);
		// TODO check if symbol is lvalue
		return new AssignStatement(cast(Variable) symTable[identTk.identifier_name], right);
	}

	ASTnode ifStatement()
	{
		expect(Token.Type.openParenthesis);
		ASTnode condition = binExpr(0);
		expect(Token.Type.closedParenthesis);

		ASTnode ifBody = compoundStatement();

		ASTnode elseBody;
		if (peekToken().type == Token.Type.K_else)
		{
			nextToken(); // skip else keyword
			elseBody = compoundStatement();
		}

		return new IfStatement(condition, ifBody, elseBody);
	}

	ASTnode compoundStatement()
	{
		ASTnode left, tree;
		
		expect(Token.type.openBrace);

		while (index < tokens.length)
		{
			Token n = nextToken();
			
			with (Token.Type) {
			switch(n.type)
			{
				case K_print:
					tree = new PrintKeyword(binExpr(0));
					expect(semicolon);
				break;
				case K_int:
					tree = varDecl(n);
					expect(semicolon);
				break;
				case identifier:
					tree = assignementStatement(n);
					expect(semicolon);
				break;
				case K_if:
					tree = ifStatement();
				break;
				case openBrace:
					index--; // walk back to pass the expect(openBrace)
					tree = compoundStatement();
				break;
				case closedBrace:
				return left;
				default:
					reportError("Syntax error line %d : token %s", n.location.lineNum, n.type);
				break;
			}
			} // with (Token.Type)

			if (tree)
			{
				if (!left)
					left = tree;
				else
					left = new Glue(tree, left);
			}

		} // while

		reportError("missing closed brace");
		return null;
	}

	void parse()
	{
		statements ~= compoundStatement();
	}

	void printAST()
	{
		foreach (stmt; statements)
			printAST(stmt);
	}

	void printAST(ASTnode node)
	{
		import std.typecons : BlackHole;

		class ASTprinter : BlackHole!ASTvisitor
		{
			uint indentLevel = 0;
			uint[] indentStack;

			void printIndent()
			{
				foreach (i; 0 .. indentLevel)
				{
					write("  ");
				}
			}

			void pushIndent()
			{
				indentStack ~= indentLevel;
			}

			void popIndent()
			{
				indentLevel = indentStack[$-1];
				indentStack = indentStack[0 .. $-1];
			}

			void print(Args...)(string msg, Args args)
			{
				printIndent();
				writefln(msg, args);
			}

			override void visit(BinExpr binNode)
			{
				pushIndent();
				indentLevel++;
				binNode.left.accept(this);
				popIndent();
				print("op : %s", binNode.opType);
				indentLevel++;
				binNode.right.accept(this);
			}

			override void visit(IntLiteral intNode)
			{
				print("int value : %d", intNode.value);
			}

			override void visit(VarDecl decl)
			{
				print("variable declaration %s : %s", decl.type, decl.varName);
			}

			override void visit(AssignStatement stmt)
			{
				print("assignation %s :", stmt.var.name);
				stmt.right.accept(this);
			}
			
			override void visit(Variable var)
			{
				print("variable : %s", var.name);
			}

			override void visit(Glue glue)
			{
				glue.left.accept(this);
				glue.tree.accept(this);
			}

			override void visit(IfStatement stmt)
			{
				print("if :");
				stmt.condition.accept(this);
				stmt.ifBody.accept(this);
				if (stmt.elseBody)
				{
					stmt.elseBody.accept(this);
				}
			}

			override void visit(PrintKeyword printNode)
			{
				print("print");
				indentLevel++;
				printNode.child.accept(this);
			}
		}

		auto printer = new ASTprinter();
		node.accept(printer);
	}

	invariant
	{
		assert(index <= tokens.length);
	}

	Variable[string] symTable;
	ASTnode[] statements;
	uint index = 0;
	Token[] tokens;
}