import std.stdio;
import std.file : write;
import std.process : execute;
import lexer;
import parser;
import code_gen;

void main(string[] args)
{
	auto lexer = new Lexer(" print 5 * 5 + 2-4; 
	print 54 * 2;");

	lexer.lex();
	auto p = new Parser(lexer.tokens);
	p.parse();
	p.printAST();

	auto cg = new X86_64_CodeGenerator(p.statements);
	cg.generateCode();
	write("a.s", cg.genCode);

	version (linux) 
	{
		int a;
		execute(["gcc", "a.s"]);
		writeln("\nstarting progam ...\n");
		execute(["./a.out"]).output.writeln;
		writeln("progam ended");
	}
}
