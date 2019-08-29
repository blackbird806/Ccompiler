import std.stdio;
import std.regex;
import std.file;
import std.format;
import std.array;
import std.conv;
import lexer;

int main(string[] args)
{
	writeln("starting compiler");
	if (args.length < 2)
	{
		writeln("error : to few arguments");
		return -1;
	}

	string sourceFile = args[1];
	auto lexer = new Lexer(readText(sourceFile));
	auto tokens = lexer.lex;
	foreach(e; tokens)
		e.str.writeln;
	writeln("files compiled successfully !\n", sourceFile);
	return 0;
}
