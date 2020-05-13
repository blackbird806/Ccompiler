import std.stdio : writeln;
import std.file : write;
import std.process : execute;
import lexer : Lexer;
import parser : Parser;
import code_gen : X86_64_CodeGenerator;

void main(string[] args)
{
	auto lexer = new Lexer(" 
	print 5 * 5 + 2-4; 
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
		execute(["gcc", "a.s"]);
		writeln("\nstarting progam ...\n");
		execute(["./a.out"]).output.writeln;
		writeln("progam ended");
	}
}
