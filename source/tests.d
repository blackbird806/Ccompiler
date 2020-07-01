module tests;

unittest
{
	import std.stdio : writeln;
	import std.file : write, readText, dirEntries, SpanMode;
	import std.process : execute;
	import std.path : extension;

	import lexer : Lexer;
	import parser : Parser, ASTnode;
	import code_gen : X86_64_CodeGenerator;

	import std.experimental.logger;

	void compile(string code)
	{
		auto lexer = new Lexer(code);
		lexer.lex();
		auto p = new Parser(lexer.tokens);
		p.parse();
		auto cg = new X86_64_CodeGenerator(cast(ASTnode[]) p.functions);
		cg.generateCode();
	}

	foreach(dirEntry; dirEntries("Ctests", SpanMode.depth))
	{
		if (dirEntry.isFile() && dirEntry.name().extension() == ".c")
		{
			log("compiling : ", dirEntry.name());
			string code = readText(dirEntry.name);
			compile(code);
		}
	}

}