module parser;

import std.stdio;
import lexer;

private void reportError(Args...)(string fmt, Args args)
{
	writefln("[parser] error " ~ fmt, args);
	debug(FatalError) assert(0);
}

// automaticly generate specialized visit method for each child of ASTNode
string genVisitMethods()
{
	import std.traits; // @suppress(dscanner.suspicious.local_imports)
	
	string codeGen;
	static foreach(memStr; __traits(allMembers, parser))
	{
		// Review check if there is no better way to ensure that our Type is a child of ASTNode
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

enum PrimitiveType
{
	int_,
	long_,
	char_,
	void_,
}

enum primitiveTypeSizes = [
	PrimitiveType.int_ 	: long.sizeof, // TODO: handle int size
	PrimitiveType.long_ : long.sizeof,
	PrimitiveType.char_ : char.sizeof,
	PrimitiveType.void_ : void.sizeof,
];

bool typeCompatible(ASTnode left, ASTnode right, bool onlyRight)
{
	with (PrimitiveType) {

	if (left.type == right.type) 
		return true;

	immutable leftSize = primitiveTypeSizes[left.type];
	immutable rightSize = primitiveTypeSizes[right.type];

	if (leftSize == 0 || rightSize == 0) 
		return false;

	if (leftSize < rightSize)
	{
		left = new Glue(left, new Widen(right.type)); // widen to right type @Review
		return true;
	}

	if (rightSize > leftSize)
	{
		right = new Glue(right, new Widen(left.type));
		return true;
	}
	return true; // same size
	}
	assert(false, "unreachable");
}

// Review
bool typeCompatible(PrimitiveType leftType, ASTnode right, bool onlyRight)
{
	with (PrimitiveType) {

	if (leftType == right.type) 
		return true;

	immutable leftSize = primitiveTypeSizes[leftType];
	immutable rightSize = primitiveTypeSizes[right.type];

	if (leftSize == 0 || rightSize == 0) 
		return false;

	if (rightSize > leftSize)
	{
		right = new Glue(right, new Widen(leftType));
		return true;
	}
	return true; // same size
	}
	assert(false, "unreachable");
}

abstract class ASTnode
{
	void accept(ASTvisitor);

	PrimitiveType type;
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
		enum opTypes = [
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
		type = PrimitiveType.int_;
	}

	int value;
}

class Widen : ASTnode
{
	mixin implementVisitor;

	this(PrimitiveType newType)
	{
		type = newType;
	}
}

class CharLiteral : ASTnode
{
	mixin implementVisitor;

	this(char v)
	{
		value = v;
	}

	char value;
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

	this(PrimitiveType t, string name)
	{
		type = t;
		varName = name;
	}

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

class WhileStatement : ASTnode
{
	mixin implementVisitor;

	this(ASTnode c, ASTnode b)
	{
		condition = c;
		whileBody = b;
	}

	ASTnode condition, whileBody;
}

// Review : I'm not sure about this way to represent symbol
interface Symbol
{
}

class Variable : ASTnode, Symbol
{
	mixin implementVisitor;

	this(PrimitiveType t, string varName)
	{
		name = varName;
		type = t;
	}

	string name;
}

class FunctionDeclaration : ASTnode, Symbol
{
	mixin implementVisitor;

	this(string name)
	{
		this.name = name;
	}

	string name;
	ASTnode funcBody;
	PrimitiveType returnType;
}

class FunctionCall : ASTnode, Symbol
{
	mixin implementVisitor;

	this(string name)
	{
		this.name = name;
	}

	string name;
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

class ReturnStatement : ASTnode
{
	mixin implementVisitor;

	this(ASTnode t)
	{
		tree = t;
	}

	ASTnode tree;
}

PrimitiveType tokenTypeToPrimitiveType(Token.Type type)
{
	switch (type)
	{
		case Token.Type.K_char: return PrimitiveType.char_;
		case Token.Type.K_int: 	return PrimitiveType.int_;
		case Token.Type.K_long: return PrimitiveType.long_;
		case Token.Type.K_void: return PrimitiveType.void_;
		default:
		assert(false, "can't convert TokenType to Primitive type");
	}
}

// https://en.cppreference.com/w/c/language/operator_precedence
enum operatorPrecedence = [	 // @suppress(dscanner.performance.enum_array_literal)
							BinExpr.Type.multiply: 		3,
							BinExpr.Type.divide: 		3,

							BinExpr.Type.add: 			4, 
							BinExpr.Type.substract: 	4,

							BinExpr.Type.less: 			6,
							BinExpr.Type.lessEqual: 	6,
							BinExpr.Type.greater: 		6,
							BinExpr.Type.greaterEqual: 	6,

							BinExpr.Type.equal: 		7,
							BinExpr.Type.notEqual: 		7,
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
		return tokens[index];
	}

	ASTnode primary()
	{
		Token tk = nextToken();
		switch(tk.type)
		{
			case Token.Type.intLiteral:
				return new IntLiteral(tk.intValue);
			case Token.Type.identifier:
				if (peekToken().type == Token.Type.openParenthesis)
					return functionCall(tk);

				if (!(tk.identifierName in symTable))
				{
					reportError("line %d : undefined identifier : %s", tk.location.lineNum, tk.identifierName);
				}
				Variable var = cast(Variable) symTable[tk.identifierName];
				if (var is null)
				{
					reportError("line %d : symbol \"%s\" is not a variable", tk.location.lineNum, tk.identifierName);
				}
				return var;
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

		while(opPrecedence(tokens[index]) < lastPred)
		{
			Token tk = nextToken();
			BinExpr.Type opType = BinExpr.toBinExprType(tk.type);
			ASTnode right = binExpr(operatorPrecedence[opType]);

			if (!typeCompatible(left, right, false))
			{
				reportError("line %s : types %s and %s are not compatibles", tk.location.lineNum, right.type, left.type);
			}

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
	
	/// add a symbol into symtable
	void addSymbol(string symName, lazy Symbol symbol)
	{
		bool symbolExist = true;
		// https://dlang.org/spec/hash-map.html#inserting_if_not_present
		symTable.require(symName, 
		{
			symbolExist = false;
			return symbol;
		}());

		if (symbolExist)
		{
			// TODO better error support
			reportError("line %d : symbol \"%s\" already defined", tokens[index].location.lineNum, symName);
		}
	}

	ASTnode varDecl(Token varTypeTk)
	{
		Token varidentTk = expect(Token.Type.identifier);
		PrimitiveType varType = tokenTypeToPrimitiveType(varTypeTk.type);

		addSymbol(varidentTk.identifierName, new Variable(varType, varidentTk.identifierName));

		return new VarDecl(varType, varidentTk.identifierName);
	}

	ASTnode assignementStatement(Token identTk)
	in(identTk.type == Token.Type.identifier)
	{
		expect(Token.Type.equal);
		ASTnode right = binExpr(int.max);
		Symbol* sym =  identTk.identifierName in symTable;

		if (sym is null)
			reportError("unrecognized var : %s", identTk.identifierName);

		Variable var = cast(Variable) *sym;
		if (var is null)
			reportError("symbol %s is not a variable", identTk.identifierName);

		if (!typeCompatible(var, right, true))
			reportError("line %s : trying to init var %s with an incompatible type : %s", 
			identTk.location.lineNum, var.type, right.type);
		
		return new AssignStatement(var, right);
	}

	ASTnode ifStatement()
	{
		expect(Token.Type.openParenthesis);
		ASTnode condition = binExpr(int.max);
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

	ASTnode whileStatement()
	{
		expect(Token.Type.openParenthesis);
		ASTnode condition = binExpr(int.max);
		expect(Token.Type.closedParenthesis);

		ASTnode whileBody = compoundStatement();

		return new WhileStatement(condition, whileBody);
	}

	ASTnode forStatement()
	{
		expect(Token.Type.openParenthesis);
		ASTnode initStmt = singleStatement();
		expect(Token.Type.semicolon);
		ASTnode condStmt = binExpr(int.max);
		expect(Token.Type.semicolon);
		ASTnode postOp = singleStatement();
		expect(Token.Type.closedParenthesis);

		ASTnode forBody = compoundStatement();

		// reinterpret the for loop as a while
		ASTnode tree = new Glue(postOp, forBody);
		tree = new WhileStatement(condStmt, tree);
		return new Glue(tree, initStmt);
	}

	ASTnode returnStatement(FunctionDeclaration fnDecl)
	{
		if (fnDecl.returnType != PrimitiveType.void_)
		{
			reportError("%s : function %s : return void", tokens[index].location, fnDecl.name);
		}
		expect(Token.type.K_return);

		ASTnode expr = binExpr(int.max);
		if (!typeCompatible(fnDecl.returnType, expr, true))
		{
			reportError("%s : function %s : must return %s, current expresion is of type %s", 
			tokens[index].location, fnDecl.returnType, expr.type);
		}

		return new ReturnStatement(expr);
	}
	
	ASTnode functionDeclaration()
	{
		PrimitiveType retType = tokenTypeToPrimitiveType(nextToken().type);
		Token ident = expect(Token.Type.identifier);
		expect(Token.Type.openParenthesis);
		// TODO : parameters 
		expect(Token.Type.closedParenthesis);

		FunctionDeclaration fn = new FunctionDeclaration(ident.identifierName);
		
		addSymbol(ident.identifierName, fn);

		fn.funcBody = compoundStatement();
		fn.returnType = retType;

		if (retType != PrimitiveType.void_)
		{
			fn.funcBody = new Glue(returnStatement(fn), fn.funcBody);
		}

		return fn;
	}

	ASTnode functionCall(Token identTk)
	{
		index++; // we already know the next token is an open parentesis
		expect(Token.Type.closedParenthesis); // TODO : handle function arguments

		if (!(identTk.identifierName in symTable))
		{
			reportError("line %d : undefined identifier : %s", identTk.location.lineNum, identTk.identifierName);
		}
		FunctionDeclaration fn = cast(FunctionDeclaration) symTable[identTk.identifierName];
		if (fn is null)
		{
			reportError("line %d : symbol \"%s\" is not a function", identTk.location.lineNum, identTk.identifierName);
		}

		return new FunctionCall(fn.name);
	}

	ASTnode singleStatement()
	{
		Token n = nextToken();
		with (Token.Type) {
		switch(n.type)
		{
			case K_print:
			ASTnode tree = binExpr(int.max);
				if (!typeCompatible(PrimitiveType.int_, tree, false))
					reportError("line %s : print expect int type got %s instead", n.location.lineNum, tree.type);
				return new PrintKeyword(tree);
			case K_int:
			case K_long:
			case K_char:
				return varDecl(n);
			case identifier:
				if (peekToken().type == Token.Type.openParenthesis)
					return functionCall(n);
				return assignementStatement(n);
			case K_if:
				return ifStatement();
			case K_while:
				return whileStatement();
			case K_for:
				return forStatement();
			case openBrace:
				index--; // walk back to pass the expect(openBrace)
				return compoundStatement();
			default:
				reportError("Syntax error line %d : token %s", n.location.lineNum, n.type);
			break;
		}
		} // with (Token.Type)
		return null;
	}

	ASTnode compoundStatement()
	{
		ASTnode left, tree;
		
		expect(Token.type.openBrace);

		while (index < tokens.length)
		{
			tree = singleStatement();

			if (tree)
			{
				const treeid = typeid(tree);
				if (treeid == typeid(PrintKeyword) || treeid == typeid(VarDecl) || treeid == typeid(AssignStatement))
				{
					expect(Token.Type.semicolon);
				}

				if (!left)
					left = tree;
				else
					left = new Glue(tree, left);
			}

			if (tokens[index].type == Token.Type.closedBrace)
			{
				expect(Token.Type.closedBrace); // consume token
				return left;
			}

		} // while

		reportError("missing closed brace");
		return null;
	}

	void parse()
	{
		while (index < tokens.length)
			functions ~= cast(FunctionDeclaration) functionDeclaration();
	}

	void printAST()
	{
		foreach(fn; functions)
		printAST(fn);
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

			override void visit(FunctionDeclaration fn)
			{
				print("function : %s", fn.name);
				indentLevel++;
				fn.funcBody.accept(this);
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

			override void visit(WhileStatement stmt)
			{
				print("while :");
				stmt.condition.accept(this);
				stmt.whileBody.accept(this);
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

	FunctionDeclaration[] functions;
	Symbol[string] symTable;
	uint index = 0;
	Token[] tokens;
}