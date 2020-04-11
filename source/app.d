import std.stdio;
import compiler;

int main(string[] args)
{
	auto lexer = new Lexer("12+564 - 5644 + 5 -5*64");
	lexer.lex();
	return 0;
}
