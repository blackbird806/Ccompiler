import std.stdio;
import compiler;

int main(string[] args)
{
	auto parser = new Parser("20/5+3*2-2*2+4*2");
	parser.lex();
	immutable r = parser.interpret();
	writeln("result ", r);
	return 0;
}
