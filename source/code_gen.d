module code_gen;

import std.format;
import std.algorithm;
import std.stdio;
import std.typecons : WhiteHole;

import parser;

private void reportError(Args...)(string fmt, Args args)
{
	import std.stdio : writefln;
	writefln("[code gen] error : " ~ fmt, args);
	version (FatalError) assert(0);
}

public interface Storage
{
	string asmLocation() const;
}

class Register : Storage
{
	this(string n)
	{
		name = n;
	}

	string asmLocation() const
	{
		return name;
	}

	string name;
}

class VarAddress : Storage
{
	this(int offset)
	{
		stackOffset = offset;
	}

	string asmLocation() const
	{
		return format!"%d(%%rbp)"(stackOffset);
	}

	int stackOffset;
}

string genRegisterArray()
{
	import std.conv : to;
	
	string code = "[";
	foreach(i; 8 .. 16)
		code ~= `new Register("%r` ~ to!string(i) ~ `"), `;
	code ~= "]";
	return code;
}

static registers = mixin(genRegisterArray());

class X86_64_CodeGenerator
{
	this(ASTnode[] entry)
	{
		entryPoints = entry;
	}

	void freeAllRegiters()
	{
		debug writefln("free all registers");
		freeRegisters = registers.dup;
	}

	void freeRegister(Register r)
	{
		if (freeRegisters.canFind!(a => a.name == r.name))
			return;
		freeRegisters ~= r;
		debug writefln("freeRegister : %s", r.name);
	}

	Register allocRegister()
	in(freeRegisters.length > 0, "no more registers available !")
	{
		auto r = freeRegisters[0];
		debug writefln("allocRegister : %s", r.name);
		freeRegisters = freeRegisters[1 .. $];
		return r;
	}

	string getUniqueName()
	{
		import std.conv : to;

		return "__tmpVar" ~ to!string(nameUid++);
	}

	Storage allocStorage()
	{
		if (freeRegisters.length > 0)
			return allocRegister();

		debug writeln("allocStorage");
		if (freedStorage.length > 0)
		{
			Storage s = freedStorage[0];
			freedStorage = freedStorage[1 .. $];
			return s;
		}

		string tmpName =  getUniqueName();
		genVariableDecl(new VarDecl(Variable.Type.int_, tmpName));
		return varAddresses[tmpName];
	}

	void freeStorage(Storage s)
	{
		debug writeln("freeStorage");

		if (typeid(s) == typeid(Register))
		{
			freeRegister(cast(Register) s);
		}
		else
		{
			freedStorage ~= s;
		}	
	}

	Register genLoad(int val)
	{
		auto register = allocRegister();
		genCode ~= format!"movq $%d, %s\n"(val, register.name);
		return register;
	}

	Register genAdd(Register r1, Register r2)
	{
		genCode ~= format!"addq %s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	Register genSub(Register r1, Register r2)
	{
		genCode ~= format!"subq %s, %s\n"(r2.name, r1.name);
		freeRegister(r2);
		return r1;
	}

	Register genMul(Register r1, Register r2)
	{
		genCode ~= format!"imulq %s, %s\n"(r1.name, r2.name);
		freeRegister(r1);
		return r2;
	}

	Register genDiv(Register r1, Register r2)
	{
		genCode ~= format!"movq %s, %%rax\n"(r1.name);
		genCode ~= "cqo\n";
		genCode ~= format!"idivq %s\n"(r2.name);
		genCode ~= format!"movq %%rax, %s\n"(r2.name);
		freeRegister(r1);
		return r2;
	}

	void genPrintRegister(Register r)
	{
		genCode ~= "lea .LC0(%rip), %rdi\n";
		genCode ~= format!"movq %s, %%rsi\n"(r.name);
		genCode ~= "xor %eax, %eax\n";
		genCode ~= "call printf@plt\n";
	}

	void genVariableDecl(VarDecl decl)
	in (!(decl.varName in varAddresses))
	{
		stackOffset -= 8; // TODO sizeof var
		varAddresses[decl.varName] = new VarAddress(stackOffset);
	}

	void genVarAssign(Variable var, Storage s)
	in (var.name in varAddresses)
	{
		debug(CommentedGen) genCode ~= format!"; assign %s\n"(var.name);
		genCode ~= format!"movq %s, %d(%%rbp)\n"(s.asmLocation(), varAddresses[var.name].stackOffset);
	}

	Register genVarStore(Variable var)
	{
		Register r = allocRegister();
		debug(CommentedGen) genCode ~= format!"; store %s\n"(var.name);
		genCode ~= format!"movq %d(%%rbp), %s\n"(varAddresses[var.name].stackOffset, r.name);
		return r;
	}
	
	void genClearRegister(Register r)
	{
		genCode ~= format!"xorq %s, %s\n"(r.name, r.name);
	}

	Register genCmp(BinExpr.Type opType)(Register r1, Register r2)
	{
		genCode ~= format!"cmpq %s, %s\n"(r2.name, r1.name);
/* 		TODO:
		const string regName8 = r2.name ~ "b"; // @Todo : func to get lower bits of registers
		with (BinExpr.Type) {
		switch(opType)
		{
			case less:
				genCode ~= format!"setl %s\n"(regName8);
			break;
			case greater:
				genCode ~= format!"setg %s\n"(regName8);
			break;
			case lessEqual:
				genCode ~= format!"setle %s\n"(regName8);
			break;
			case greaterEqual:
				genCode ~= format!"setge %s\n"(regName8);
			break;
			case equal:
				genCode ~= format!"sete %s\n"(regName8);
			break;
			case notEqual:
				genCode ~= format!"setne %s\n"(regName8);
			break;
			default:
			assert(false, "type is not a cmp operator");
		}
		} // with (BinExpr.Type)
		genCode ~= format!"andq $255, %s\n"(r2.name);
		*/
		freeRegister(r1);
		return r2;
	}

	uint createLabel()
	{
		return nextLabelId++;
	}

	void genLabel(uint labelId)
	{
		genCode ~= format!"L%d:\n"(labelId);
	}

	void genJump(uint labelId)
	{
		genCode ~= format!"jmp L%d\n"(labelId);
	}

	void genCondJump(ConditionalStmt)(ConditionalStmt stmt, uint targetLabel)
	{
		if (typeid(stmt.condition) == typeid(BinExpr))
		{
			auto expr = cast(BinExpr) stmt.condition;
			with (BinExpr.Type) {
			switch(expr.opType)
			{
				// we want to jump only if the condition is false 
				case less:
					genCode ~= format!"jg L%s\n"(targetLabel);
				break;
				case greater:
					genCode ~= format!"jl L%s\n"(targetLabel);
				break;
				case lessEqual:
					genCode ~= format!"jge L%s\n"(targetLabel);
				break;
				case greaterEqual:
					genCode ~= format!"jle L%s\n"(targetLabel);
				break;
				case equal:
					genCode ~= format!"jne L%s\n"(targetLabel);
				break;
				case notEqual:
					genCode ~= format!"je L%s\n"(targetLabel);
				break;

				default:
				goto arithemtic; // ahem
			}
			} // with (BinExpr.Type)
		} // if binexpr
		else if (typeid(stmt.condition) == typeid(IntLiteral))
		{
			arithemtic:
			Register result = generateASM(stmt.condition);
			genCode ~= format!"jne L%s\n"(targetLabel);
		}
		else
		{
			reportError("bad condition in if statment");
		}
	}

	void genIfStatement(IfStatement n)
	{
		Register result = generateASM(n.condition);
		uint endLabel = createLabel();
		uint elseLabel = createLabel();
		
		genCondJump(n, n.elseBody ? elseLabel : endLabel);

		generateASM(n.ifBody);
		freeAllRegiters();

		if (n.elseBody)
		{
			genJump(endLabel);
			genLabel(elseLabel);
			generateASM(n.elseBody);
			freeAllRegiters();
		}
		genLabel(endLabel);
	}

	void genWhileStatement(WhileStatement n)
	{
		uint startLabel = createLabel();
		uint endLabel = createLabel();
		genLabel(startLabel);

		Register result = generateASM(n.condition);
		freeAllRegiters();
		
		genCondJump(n, endLabel);

		generateASM(n.whileBody);
		freeAllRegiters();

		genJump(startLabel);
		genLabel(endLabel);
	}

	void genPreamble()
	{
		genCode ~=
		".text\n" ~ 
		".LC0:\n" ~ 
		`.string "out %d\n"` ~ "\n" ~
		".globl main\n" ~
		"main:\n" ~
        "pushq %rbp\n" ~
        "movq %rsp, %rbp\n" ~
		"subq $512, %rsp\n"
		;
	}

	void genPostamble()
	{
		genCode ~= "addq $512, %rsp\n";
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
				
				// @TODO : find a more elegant way to do this

				case BinExpr.Type.equal:
					return genCmp!(BinExpr.Type.equal)(left, right);

				case BinExpr.Type.notEqual:
					return genCmp!(BinExpr.Type.notEqual)(left, right);

				case BinExpr.Type.less:
					return genCmp!(BinExpr.Type.less)(left, right);

				case BinExpr.Type.lessEqual:
					return genCmp!(BinExpr.Type.lessEqual)(left, right);

				case BinExpr.Type.greater:
					return genCmp!(BinExpr.Type.greater)(left, right);

				case BinExpr.Type.greaterEqual:
					return genCmp!(BinExpr.Type.greaterEqual)(left, right);

				default:
					assert(false, "unrecognized binexpr");
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
			freeAllRegiters();
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
		else if (type == typeid(Glue))
		{
			auto glue = cast(Glue) node;
			generateASM(glue.left);
			freeAllRegiters();
			generateASM(glue.tree);
			freeAllRegiters();
		}
		else if (type == typeid(IfStatement))
		{
			genIfStatement(cast(IfStatement) node);
		}
		else if (type == typeid(WhileStatement))
		{
			genWhileStatement(cast(WhileStatement) node);
		}
		else
		{
			reportError("bad ASTNode type : %s", node);
		}

		// @TODO : I should not waste a register if not needed 
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
	
	Storage[] freedStorage;

	uint nameUid;
	uint nextLabelId;
	
	int stackOffset;
	VarAddress[string] varAddresses;
}