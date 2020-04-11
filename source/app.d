import std.stdio;
import compiler;

int main(string[] args)
{
	auto parser = new Parser("32+5+1+2+3+4");
	parser.lex();
	immutable r = parser.interpret();
	writeln("result ", r);
	return 0;
}
