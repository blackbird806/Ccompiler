module code_generator;

import parser;
import lexer;

string generateFunc(AST.FunDecl fn, AST.FunBody body)
{
	string code = ".globl _" ~ fn.name.str ~ "\n";
	code ~= "_" ~ fn.name.str ~ ":\n";
	code ~= "xor eax\nret";
	return code;
}