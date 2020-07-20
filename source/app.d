import std.stdio : writeln;
import std.file : write;
import std.process : execute;
import lexer : Lexer;
import parser : Parser, ASTnode;
import code_gen : X86_64_CodeGenerator;

void main(string[] args)
{
	auto lexer = new Lexer(q{

			void main()
			{
				long a;
				a = 5;
				long b;
				b = a - 1;
				print a;
			}

		});

	debug writeln("======== start lexing ========");
	lexer.lex();
	debug writeln("======== end lexing ========");
	
	auto p = new Parser(lexer.tokens);
	debug writeln("======== start parsing ========");
	p.parse();
	debug writeln("======== end parsing ========");

	debug p.printAST();

	auto cg = new X86_64_CodeGenerator(cast(ASTnode[]) p.functions);
	debug writeln("======== start code gen ========");
	cg.generateCode();
	debug writeln("======== end code gen ==========");

	write("a.s", cg.genCode);

	version (linux)
	{
		execute(["gcc", "-g", "a.s"]);
		writeln("\nstarting progam ...\n");
		execute(["./a.out"]).output.writeln;
		writeln("progam ended");
	}
}
