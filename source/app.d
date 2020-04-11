import std.stdio;
import std.file;
import std.conv;

import lexer;
import parser, better_parser;
import code_generator;

int main(string[] args)
{
	writeln("starting compiler");
	if (args.length < 2)
	{
		writeln("error : to few arguments");
		return -1;
	}
	string sourceFile = args[1];

	string source;
	try {
		source = readText(sourceFile); 
	} 
	catch(FileException e) 
	{
		e.msg.writeln();
		return -1;
	}

	auto lexer = new Lexer(source);
	auto tokens = lexer.lex;

	writeln("\n");
	foreach(e; tokens) {
		e.str.write(); 
		writeln(" \t: ", e.type);
	}
	writeln("\n");

	auto parser = new BetterParser(tokens);
	parser.parse();

	// auto parser = new Parser(tokens);
	// AST ast = parser.parse();

	writefln("file %s compiled successfully !", sourceFile);
	return 0;
}
