unittest
{
	import std.stdio;
	import std.file;
	import std.process : execute;
	import std.path;

	import lexer : Lexer;
	import parser : Parser, ASTnode;
	import code_gen : X86_64_CodeGenerator;

	void compileAndRun(string code, string expectedOutput = "")
	{
		auto lexer = new Lexer(code);
		lexer.lex();
		auto p = new Parser(lexer.tokens);
		p.parse();
		auto cg = new X86_64_CodeGenerator(cast(ASTnode[]) p.functions);
		cg.generateCode();

		std.file.write("a.s", cg.genCode);

		version (linux)
		{
			auto linkExec = execute(["gcc", "-g", "a.s"]);
			assert(linkExec.status == 0, "compilation failed: " ~ linkExec.output);

			writeln("\nstarting progam ...\n");
			auto runExec = execute(["./a.out"]);
			assert(runExec.status == 0, "execution failed");

			if (expectedOutput.length > 0)
			{
				if (runExec.output == expectedOutput)
				{
					writeln("TEST PASSED : ");
				}
				else
				{
					std.stdio.writefln("TEST FAILED :\n%s", runExec.output);
					std.stdio.writefln("expected :\n%s", expectedOutput);
				}
			}
			writeln(runExec.output);
			writeln("progam ended");
		}
	}

	foreach(dirEntry; dirEntries("Ctests", SpanMode.depth))
	{
		if (dirEntry.isFile() && dirEntry.name().extension() == ".c")
		{
			writeln("compiling : ", dirEntry.name());
			const code = readText(dirEntry.name);
			auto outputFile = dirEntry.name().setExtension(".test");
			if (exists(outputFile))
			{
				compileAndRun(code, readText(outputFile));
			}
			else
			{
				compileAndRun(code, "");
			}
		}
	}

}