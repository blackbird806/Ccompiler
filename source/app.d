import std.stdio;
import std.file : write;
import compiler;

int main(string[] args)
{
	auto cmp = new Compiler("25 * 4+ 2/1*8 /2");
	cmp.lex();
	// immutable r = cmp.interpret();
	// writeln("result ", r);
	cmp.compile();

	write("a.s", cmp.genCode);
	return 0;
}
