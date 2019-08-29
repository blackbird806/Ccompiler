import std.stdio;
import std.regex;
import std.file;
import std.format;
import std.array;
import std.conv;

enum string assemblyFormat = 
"
.globl main
main:
mov eax, %d
ret
";

int main(string[] args)
{
	writeln("starting compiler");
	if (args.length < 2)
	{
		writeln("error : to few arguments");
		return -1;
	}

	string sourceFile = args[1];
	auto source_re = regex(r"int main\s*\(\s*\)\s*\{\s*return\s+(?P<ret>[0-9]+)\s*;\s*\}");
	immutable string source = readText(sourceFile);
	auto match = source.matchFirst(source_re);
	immutable int retVal = match["ret"].to!int;
	std.file.write(sourceFile.replace(".c", ".s"), format(assemblyFormat, retVal));

	writeln("files compiled successfully !");
	return 0;
}
