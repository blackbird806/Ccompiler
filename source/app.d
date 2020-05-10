import std.stdio;
import std.file : write;
import std.process : execute;
import compiler;
import lexer;
import parser;
import code_gen;


void main(string[] args)
{
	auto lexer = new Lexer("5 *  5+20 - 1");
	lexer.lex();
	auto p = new Parser(lexer.tokens);
	p.parse();
	auto cg = new X86_64_CodeGenerator(p.entryPoint);
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
