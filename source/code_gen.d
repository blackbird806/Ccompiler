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
	debug(FatalError) assert(0);
}

class Register
{
	this(string n64, string n32, string n16, string n8)
	{
		name64 = n64;
		name32 = n32;
		name16 = n16;
		name8 = n8;
	}

	string regNameFromSize(int size)
	{
		switch (size)
		{
			case 1:
				return name8;
			case 2:
				return name16;
			case 4:
				return name32;
			case 8:
				return name64;
			default:
				assert(0, "size must be either 1, 2, 4 or 8 bytes !");
		}
	}

	alias name = name64;
	
	immutable string name64, name32, name16, name8;
}

class VarAddress
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

static registers = mixin(
	{
		import std.conv : to;
		
		string code = "[";
		foreach(i; 8 .. 16)
		{
			string regName = "%r" ~ to!string(i);
			code ~= `new Register("` 
				/*64 bits*/ ~ regName ~ `", "` 
				/*32 bits*/ ~ regName ~ `d", "`
				/*16 bits*/ ~ regName ~ `w", "`
				/* 8 bits*/ ~ regName ~ `b"), `;
		}
		code ~= "]";
		return code;
	}()
);

enum movInstr = [
	1 : "movb",
	4 : "movl",
	8 : "movq",
];

class X86_64_CodeGenerator
{
	this(ASTnode[] entryPoints)
	{
		this.entryPoints = entryPoints;
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
		// debug writefln("freeRegister : %s", r.name);
	}

	Register allocRegister()
	in(freeRegisters.length > 0, "no more registers available !")
	{
		auto r = freeRegisters[0];
		// debug writefln("allocRegister : %s", r.name);
		freeRegisters = freeRegisters[1 .. $];
		return r;
	}

	string getUniqueName()
	{
		import std.conv : to;

		return "__tmpVar" ~ to!string(nameUid++);
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
		stackOffset -= primitiveTypeSizes[decl.type]; 
		varAddresses[decl.varName] = new VarAddress(stackOffset);
	}

	void genVarAssign(Variable var, Register r)
	in (var.name in varAddresses)
	{
		debug(CommentedGen) genCode ~= format!"; assign %s\n"(var.name);
		genCode ~= movInstr[cast(int) primitiveTypeSizes[var.type]]; // gen mov according to the size of var
		genCode ~= format!" %s, %d(%%rbp)\n"(r.name64, varAddresses[var.name].stackOffset);
	}

	Register genVarStore(Variable var)
	{
		Register r = allocRegister();
		debug(CommentedGen) genCode ~= format!"; store %s\n"(var.name);
		genCode ~= movInstr[cast(int) primitiveTypeSizes[var.type]]; // gen mov according to the size of var
		genCode ~= format!" %d(%%rbp), %s\n"(varAddresses[var.name].stackOffset, r.name);
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
				case less:
					genCode ~= format!"jl L%s\n"(targetLabel);
				break;
				case greater:
					genCode ~= format!"jg L%s\n"(targetLabel);
				break;
				case lessEqual:
					genCode ~= format!"jle L%s\n"(targetLabel);
				break;
				case greaterEqual:
					genCode ~= format!"jge L%s\n"(targetLabel);
				break;
				case equal:
					genCode ~= format!"je L%s\n"(targetLabel);
				break;
				case notEqual:
					genCode ~= format!"jne L%s\n"(targetLabel);
				break;

				default:
				goto arithemtic; // ahem
			}
			} // with (BinExpr.Type)
		} // if binexpr
		else if (typeid(stmt.condition) == typeid(IntLiteral))
		{
			arithemtic:
			Register result = genBinExpr(cast(BinExpr) stmt.condition);
			genCode ~= format!"jz L%s\n"(targetLabel);
		}
		else
		{
			reportError("bad condition in if statment");
		}
	}
	
	// TODO:
	// not proud of this
	void genInvertCondJump(ConditionalStmt)(ConditionalStmt stmt, uint targetLabel)
	{
		if (typeid(stmt.condition) == typeid(BinExpr))
		{
			auto expr = cast(BinExpr) stmt.condition;
			with (BinExpr.Type) {
			switch(expr.opType)
			{
				case less:
					genCode ~= format!"jge L%s\n"(targetLabel);
				break;
				case greater:
					genCode ~= format!"jle L%s\n"(targetLabel);
				break;
				case lessEqual:
					genCode ~= format!"jg L%s\n"(targetLabel);
				break;
				case greaterEqual:
					genCode ~= format!"jl L%s\n"(targetLabel);
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
			Register result = genBinExpr(cast(BinExpr) stmt.condition);
			genCode ~= format!"jnz L%s\n"(targetLabel);
		}
		else
		{
			reportError("bad condition in if statment");
		}
	}

	void genIfStatement(IfStatement n)
	{
		generateASM(n.condition);
		freeAllRegiters();

		uint endLabel = createLabel();
		uint elseLabel = createLabel();
		
		genInvertCondJump(n, n.elseBody ? elseLabel : endLabel);

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
		uint cmpLabel = createLabel();
		uint startLabel = createLabel();

		genJump(cmpLabel);
		genLabel(startLabel);

		generateASM(n.whileBody);
		freeAllRegiters();

		genLabel(cmpLabel);
		Register result = genBinExpr(cast(BinExpr) n.condition);
		genCondJump(n, startLabel);
		freeAllRegiters();
	}

	void genWiden()
	{

	}

	void genPreample()
	{
		genCode ~= ".text\n" ~ 
		".LC0:\n" ~ 
		`.string "out %d\n"` ~ "\n";
	}

	void genFnPreamble(FunctionDeclaration fn)
	{
		genCode ~= ".text\n" ~
		format!".globl %s\n"(fn.name) ~
		format!".type %s, @function\n"(fn.name) ~
		format!"%s:\n"(fn.name) ~
		"pushq %rbp\n" ~
		"movq %rsp, %rbp\n" ~
		"subq $512, %rsp\n";
	}

	void genFnPostamble()
	{
		genCode ~= "movl $0, %eax\n" ~
		"popq %rbp\n" ~
		"addq $512, %rsp\n" ~
		"ret\n";
	}

	Register genBinExpr(ASTnode node)
	{
		TypeInfo type = typeid(node);

		if (type == typeid(BinExpr))
		{	
			auto binNode = cast(BinExpr) node;

			Register left, right;
			if (binNode.left)
				left = genBinExpr(binNode.left);
			if (binNode.right)
				right = genBinExpr(binNode.right);

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
					
				// TODO : find a more elegant way to do this

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
		else if (type == typeid(Variable))
		{
			return genVarStore(cast(Variable) node);
		}
		assert(false, "unrecognized expr");
	}

	// generate compound statement
	void generateASM(ASTnode node)
	{
		TypeInfo type = typeid(node);

		if (type == typeid(BinExpr))
		{
			genBinExpr(cast(BinExpr) node);
		}
		else if (type == typeid(IntLiteral))
		{
			IntLiteral intNode = cast(IntLiteral) node;
			genLoad(intNode.value);
		}
		else if (type == typeid(PrintKeyword))
		{
			PrintKeyword printNode = cast(PrintKeyword) node;
			genPrintRegister(genBinExpr(printNode.child));
			freeAllRegiters();
		}
		else if (type == typeid(VarDecl))
		{
			genVariableDecl(cast(VarDecl) node);
		}
		else if (type == typeid(AssignStatement))
		{
			AssignStatement assignNode = cast(AssignStatement) node;
			genVarAssign(assignNode.var, genBinExpr(assignNode.right));
		}
		else if (type == typeid(Variable))
		{
			genVarStore(cast(Variable) node);
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
		else if (type == typeid(FunctionDeclaration))
		{
			FunctionDeclaration fn = cast(FunctionDeclaration) node;
			genFnPreamble(fn);
			generateASM(fn.funcBody);
			genFnPostamble();
		}
		else if (type == typeid(Widen))
		{
			genWiden();
		}
		else
		{
			reportError("bad ASTNode type : %s", node);
		}
	}

	void generateCode()
	{
		freeAllRegiters();
		genPreample();
		foreach(entryPoint; entryPoints)
			generateASM(entryPoint);
	}

	ASTnode[] entryPoints;
	string genCode;
	Register[] freeRegisters;
	
	uint nameUid;
	uint nextLabelId;
	
	int stackOffset;
	VarAddress[string] varAddresses;
}