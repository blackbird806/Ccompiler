import std.stdio;
import std.file : write;
import std.process : execute;
import compiler;

void main(string[] args)
{
	auto cmp = new Compiler("5*5+20-10");
	cmp.lex();
	cmp.compile();
	write("a.s", cmp.genCode);
	
	// execute(["gcc", "a.s"]);
	// writeln("\nstarting progam ...\n");
	// execute(["./a.out"]).output.writeln;
	// writeln("progam ended");
}
