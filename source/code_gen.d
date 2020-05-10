// module code_gen;

// import std.format;
// import std.algorithm;

// struct Register
// {
// 	string name;
// 	int value;
// }

// static immutable registers = [ Register("%r8"), Register("%r9"), Register("%r10"), Register("%r11") ];

// class X86_64_CodeGenerator
// {
// 	void freeAllRegiters()
// 	{
// 		freeRegisters = registers.dup;
// 	}

// 	void freeRegister(Register r)
// 	{
// 		if (freeRegisters.canFind!(a => a.name == r.name))
// 			return;
// 		freeRegisters ~= r;
// 	}

// 	auto allocRegister()
// 	{
// 		assert(freeRegisters.length > 0);
// 		auto r = freeRegisters[0];
// 		freeRegisters = freeRegisters[1 .. $];
// 		return r;
// 	}

// 	auto genLoad(int val)
// 	{
// 		auto register = allocRegister();
// 		register.value = val;
// 		genCode ~= format!"movq\t$%d, %s\n"(val, register.name);
// 		return register;
// 	}

// 	auto genAdd(Register r1, Register r2)
// 	{
// 		genCode ~= format!"addq\t%s, %s\n"(r1.name, r2.name);
// 		freeRegister(r1);
// 		return r2;
// 	}

// 	auto genSub(Register r1, Register r2)
// 	{
// 		genCode ~= format!"subq\t%s, %s\n"(r2.name, r1.name);
// 		freeRegister(r2);
// 		return r1;
// 	}

// 	auto genMul(Register r1, Register r2)
// 	{
// 		genCode ~= format!"imulq\t%s, %s\n"(r1.name, r2.name);
// 		freeRegister(r1);
// 		return r2;
// 	}

// 	auto genDiv(Register r1, Register r2)
// 	{
// 		genCode ~= format!"movq\t%s, %%rax\n"(r1.name);
// 		genCode ~= "cqo\n";
// 		genCode ~= format!"idivq\t%s\n"(r2.name);
// 		genCode ~= format!"movq\t%%rax, %s\n"(r2.name);
// 		freeRegister(r1);
// 		return r2;
// 	}

// 	void printRegister(Register r)
// 	{
// 		genCode ~= format!"lea .LC0(%%rip), %%rdi\n";
// 		genCode ~= format!"movq %s, %%rsi\n"(r.name);
// 		genCode ~= "call printf\n";
// 	}

// 	void genPreamble()
// 	{
// 		genCode ~=
// 		".text\n" ~ 
// 		".LC0:\n" ~ 
// 		`.string "num %d\n"` ~ "\n" ~
// 		".globl main\n" ~
// 		"main:\n" ~
//         "pushq   %rbp\n" ~
//         "movq    %rsp, %rbp\n";
// 	}

// 	void genPostamble()
// 	{
// 		genCode ~= "movq $0, %rax\npopq %rbp\nret\n";
// 	}

// 	Register genAST(ASTnode node)
// 	{
// 		Register left, right;
// 		if (node.left !is null)
// 			left = genAST(node.left);

// 		if (node.right !is null)
// 			right = genAST(node.right);

// 		switch(node.type)
// 		{
// 			case ASTnode.Type.add:
// 				return cgAdd(left, right);
				
// 			case ASTnode.Type.substract:
// 				return cgSub(left, right);
				
// 			case ASTnode.Type.divide:
// 				return cgDiv(left, right);
				
// 			case ASTnode.Type.multiply:
// 				return cgMul(left, right);

// 			case ASTnode.Type.intLiteral:
// 				return cgLoad(node.value);
			
// 			default:
// 				assert(false);
// 		}
// 	}

// 	string genCode;
// 	Register[] freeRegisters;
// }