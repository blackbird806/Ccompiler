import lexer;
import std.stdio;
import std.file;

unittest
{
	void testFile(string filePath)
	{
		immutable source = readText(filePath); 
		auto lexer = new Lexer(source);
		auto tokens = lexer.lex;

		writeln("\n");
		foreach(e; tokens) {
			e.str.write(); 
			writeln(" \t: ", e.type);
		}
		writeln("\n");
	}

	testFile("Ctests/test1.c");
	testFile("Ctests/week1.c");
}