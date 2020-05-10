import std.stdio;
import std.file : write;
import std.process : execute;
import compiler;
import lexer;
import parser;
import code_gen;


void main(string[] args)
{

	Parser p = new Parser(new Token[5]);
	X86_64_CodeGenerator cg = new X86_64_CodeGenerator(p.entryPoint);
	cg.generateCode();
	// auto cmp = new Compiler("5*5+20-10");
	// cmp.lex();
	// cmp.compile();
	write("a.s", cg.genCode);
	
	// execute(["gcc", "a.s"]);
	// writeln("\nstarting progam ...\n");
	// execute(["./a.out"]).output.writeln;
	// writeln("progam ended");
}
