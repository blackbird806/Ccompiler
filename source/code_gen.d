module code_gen;

import std.format;
import std.algorithm;

import parser;

private void reportError(Args...)(string fmt, Args args)
{
	import std.stdio :writefln;
	writefln("[code gen] error : " ~ fmt, args);
}

struct Register
{
	string name;
	int value;
}

struct VarAdress
{
	int stackOffset;
}

auto genRegisterArray()
{
	import std.conv : to;
	
	string code = "[";
	foreach(i; 8 .. 16)
	{
		code ~= `Register("%r` ~ to!string(i) ~ `"), `;
	}
	code ~= "]";
	return code;
}

static immutable registers = mixin(genRegisterArray());

class X86_64_CodeGenerator
{
	this(ASTnode[] entry)
	{
		entryPoints = entry;
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

	Register allocRegister()
	{
		assert(freeRegisters.length > 0, "no more registers available !");
		auto r = freeRegisters[0];
		freeRegisters = freeRegisters[1 .. $];
		return r;
	}

	Register genLoad(int val)
	{
		auto register = allocRegister();
		register.value = val;
		genCode ~= format!"movq\t$%d, %s\n"(val, register.name);
		return register;
	}

	Register genAdd(Register r1, Register r2)
	{
		genCode ~= format!"addq\t%s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	Register genSub(Register r1, Register r2)
	{
		genCode ~= format!"subq\t%s, %s\n"(r2.name, r1.name);
		freeRegister(r2);
		return r1;
	}

	Register genMul(Register r1, Register r2)
	{
		genCode ~= format!"imulq\t%s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	Register genDiv(Register r1, Register r2)
	{
		genCode ~= format!"movq\t%s, %%rax\n"(r1.name);
		genCode ~= "cqo\n";
		genCode ~= format!"idivq\t%s\n"(r2.name);
		genCode ~= format!"movq\t%%rax, %s\n"(r2.name);
		freeRegister(r1);
		return r2;
	}

	void genPrintRegister(Register r)
	{
		genCode ~= format!"lea .LC0(%%rip), %%rdi\n";
		genCode ~= format!"movq %s, %%rsi\n"(r.name);
		genCode ~= "call printf\n";
	}

	void genVariableDecl(VarDecl decl)
	in (!(decl.varName in varAddresses))
	{
		stackOffset -= 4; // TODO sizeof var
		varAddresses[decl.varName] = VarAdress(stackOffset);
	}

	void genVarAssign(Variable var, Register r)
	in (var.name in varAddresses)
	{
		genCode ~= format!"movq %s, %d(%%rbp)\n"(r.name, varAddresses[var.name].stackOffset);
	}

	Register genVarStore(Variable var)
	{
		Register r = allocRegister();
		genCode ~= format!"movq %d(%%rbp), %s\n"(varAddresses[var.name].stackOffset, r.name);
		return r;
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

	Register generateASM(ASTnode node)
	{
		Register left, right;
		TypeInfo type = typeid(node);

		if (type == typeid(BinExpr))
		{
			BinExpr binNode = cast(BinExpr) node;
			if (binNode.left)
				left = generateASM(binNode.left);
			if (binNode.right)
				right = generateASM(binNode.right);

			switch(binNode.opType)
			{
				case BinExpr.Type.add:
					return genAdd(left, right);
					
				case BinExpr.Type.substract:
					return genSub(left, right);
					
				case BinExpr.Type.divide:
					return genDiv(left, right);
					
				case BinExpr.Type.multiply:
					return genMul(left, right);
					
				default:
					assert(false);
			}
		}
		else if (type == typeid(IntLiteral))
		{
			IntLiteral intNode = cast(IntLiteral) node;
			return genLoad(intNode.value);
		}
		else if (type == typeid(PrintKeyword))
		{
			PrintKeyword printNode = cast(PrintKeyword) node;
			genPrintRegister(generateASM(printNode.child));
		}
		else if (type == typeid(VarDecl))
		{
			genVariableDecl(cast(VarDecl) node);
		}
		else if (type == typeid(AssignStatement))
		{
			AssignStatement assignNode = cast(AssignStatement) node;
			genVarAssign(assignNode.var, generateASM(assignNode.right));
		}
		else if (type == typeid(Variable))
		{
			return genVarStore(cast(Variable) node);
		}
		else
		{
			reportError("bad ASTNode type : %s", node);
		}
		return allocRegister();
	}

	void generateCode()
	{
		freeAllRegiters();
		genPreamble();
		foreach (entry; entryPoints)
			auto result = generateASM(entry);
		genPostamble();
	}

	ASTnode[] entryPoints;
	string genCode;
	Register[] freeRegisters;
	
	int stackOffset;
	VarAdress[string] varAddresses;
}