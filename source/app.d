import std.stdio;
import std.file : write;
import compiler;

int main(string[] args)
{
	auto cmp = new Compiler("5*3+2+8/4");
	cmp.lex();
	// immutable r = cmp.interpret();
	// writeln("result ", r);
	cmp.compile();

	write("a.s", cmp.genCode);
	return 0;
}
