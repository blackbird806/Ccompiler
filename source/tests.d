unittest
{
	import std.stdio : writeln;
	import std.file : write, readText, dirEntries, SpanMode;
	import std.process : execute;
	import std.path : extension;

	import lexer : Lexer;
	import parser : Parser, ASTnode;
	import code_gen : X86_64_CodeGenerator;

	void compileAndRun(string code)
	{
		auto lexer = new Lexer(code);
		lexer.lex();
		auto p = new Parser(lexer.tokens);
		p.parse();
		auto cg = new X86_64_CodeGenerator(cast(ASTnode[]) p.functions);
		cg.generateCode();

		write("a.s", cg.genCode);

		version (linux)
		{
			auto exec = execute(["gcc", "-g", "a.s"]);
			assert(exec.status == 0, "compilation failed");

			writeln("\nstarting progam ...\n");
			exec = execute(["./a.out"]);
			assert(exec.status == 0, "execution failed");
			exec.output.writeln();
			writeln("progam ended");
		}
	}

	foreach(dirEntry; dirEntries("Ctests", SpanMode.depth))
	{
		if (dirEntry.isFile() && dirEntry.name().extension() == ".c")
		{
			writeln("compiling : ", dirEntry.name());
			string code = readText(dirEntry.name);
			compileAndRun(code);
		}
	}

}