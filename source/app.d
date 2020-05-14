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
	print 25 / 2;
	
	");
	
	debug writeln("======== start lexing ========");
	lexer.lex();
	debug writeln("======== end lexing ========");
	
	auto p = new Parser(lexer.tokens);
	debug writeln("======== start parsing ========");
	p.parse();
	debug writeln("======== end parsing ========");

	p.printAST();

	auto cg = new X86_64_CodeGenerator(p.statements);
	debug writeln("======== start code gen ========");
	cg.generateCode();
	debug writeln("======== end code gen ========");

	write("a.s", cg.genCode);

	version (linux)
	{
		execute(["gcc", "a.s"]);
		writeln("\nstarting progam ...\n");
		execute(["./a.out"]).output.writeln;
		writeln("progam ended");
	}
}
