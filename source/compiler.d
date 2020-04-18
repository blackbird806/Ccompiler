module compiler;
import std.stdio;
import std.uni;
import std.conv;
import std.format;
import std.algorithm;

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

enum operatorPrecedence = [	ASTnode.Type.add: 1, ASTnode.Type.substract: 1,  // @suppress(dscanner.performance.enum_array_literal)
										ASTnode.Type.multiply: 2, ASTnode.Type.divide: 2];

static immutable registers = [Register("%r8"), Register("%r9"), Register("%r10"), Register("%r11")];

class Compiler
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

	auto opPrecedence(Token tk)
	{
		if (tk.toArithmeticOp !in operatorPrecedence)
		{
			writeln("syntax error token : ", tk);
			assert(false);
		}
		return operatorPrecedence[tk.toArithmeticOp];
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

	auto binExpr(int lastPred)
	{
		auto left = primary();
		if (tokenIndex >= tokens.length)
			return left;

		while(opPrecedence(tokens[tokenIndex]) > lastPred)
		{
			auto tk = nextToken();
			auto right = binExpr(operatorPrecedence[tk.toArithmeticOp()]);
			left = new ASTnode(tk.toArithmeticOp(), left, right);
			if (tokenIndex >= tokens.length)
				break;
		}

		return left;
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
		return interpret(binExpr(0));
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

	void freeAllRegiters()
	{
		freeRegisters = registers.dup;
	}

	void freeRegister(Register r)
	{
		if (freeRegisters.canFind!(a => a.name == r.name))
			return;
		freeRegisters ~= r;
	}

	auto allocRegister()
	{
		assert(freeRegisters.length > 0);
		auto r = freeRegisters[0];
		freeRegisters = freeRegisters[1 .. $];
		return r;
	}

	auto cgLoad(int val)
	{
		auto register = allocRegister();
		register.value = val;
		genCode ~= format!"movq\t$%d, %s\n"(val, register.name);
		return register;
	}

	auto cgAdd(Register r1, Register r2)
	{
		genCode ~= format!"addq\t%s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	auto cgSub(Register r1, Register r2)
	{
		genCode ~= format!"subq\t%s, %s\n"(r2.name, r1.name);
		freeRegister(r2);
		return r1;
	}

	auto cgMul(Register r1, Register r2)
	{
		genCode ~= format!"imulq\t%s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	auto cgDiv(Register r1, Register r2)
	{
		genCode ~= format!"movq\t%s, %%rax\n"(r1.name);
		genCode ~= "cqo\n";
		genCode ~= format!"idivq\t%s\n"(r2.name);
		genCode ~= format!"movq\t%%rax, %s\n"(r2.name);
		freeRegister(r1);
		return r2;
	}

	void cgPrintRegister(Register r)
	{
		genCode ~= format!"lea .LC0(%%rip), %%rdi\n";
		genCode ~= format!"movq %s, %%rsi\n"(r.name);
		genCode ~= "call printf\n";
	}

	Register genAST(ASTnode node)
	{
		Register left, right;
		if (node.left !is null)
			left = genAST(node.left);

		if (node.right !is null)
			right = genAST(node.right);

		switch(node.type)
		{
			case ASTnode.Type.add:
				return cgAdd(left, right);
				
			case ASTnode.Type.substract:
				return cgSub(left, right);
				
			case ASTnode.Type.divide:
				return cgDiv(left, right);
				
			case ASTnode.Type.multiply:
				return cgMul(left, right);

			case ASTnode.Type.intLiteral:
				return cgLoad(node.value);
			
			default:
				assert(false);
		}
	}

	void genPreamble()
	{
		genCode ~=
		".text\n" ~ 
		".LC0:\n" ~ 
		`.string "num %d\n"` ~ "\n" ~
		".globl main\n" ~
		"main:\n" ~
        "pushq   %rbp\n" ~
        "movq    %rsp, %rbp\n";
	}

	void genPostamble()
	{
		genCode ~= "movq $0, %rax\npopq %rbp\nret\n";
	}

	void compile()
	{
		freeAllRegiters();
		genPreamble();
		auto result = genAST(binExpr(0));
		cgPrintRegister(result);
		genPostamble();
	}

	invariant
	{
		assert(index <= source.length);
	}

	Token[] tokens;
	Register[] freeRegisters;
	string source;
	string genCode;
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

struct Register
{
	string name;
	int value;
}