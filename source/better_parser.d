module better_parser;
import std.stdio, std.string, std.algorithm;
import std.traits;
import std.typecons, std.conv;

import lexer;

alias reportError = writeln;

void check(bool cond)
{
	assert(cond);
}

enum Type
{
	void_,
	int_
}

class Arg
{
	Type type;
	string name;
}

class Function
{
	void print()
	{
		writef("func: %s(", name);
		foreach (arg; args)
		{
			write(arg.type, arg.name, ", ");
		}
		writeln(")");
	}

	string name;
	Arg[] args;
	Type returnType;
}

enum Type[string] keywords = [ 	"int":    Type.int_,
                                "void":   Type.void_];

auto getType(Token tk)
{
	check(tk.isLanguageType);
	return keywords[tk.str];
}

class BetterParser
{
	this(Token[] tokenList)
	{
		tokens = tokenList;	
	}
	
	auto peek(uint i = 0)
	{
		return tokens[index + i];
	}

	auto eat()
	{
		return tokens[index++];
	}

	auto parseFunctionParameters()
	{
		Arg[] params;
		while(peek().type != TokenType.closedParenthesis)
		{
			auto tk = eat();
			auto param = new Arg();
			param.type = tk.getType();
			if (peek().type == TokenType.identifier)
			{
				param.name = eat().str;
			}
			params ~= param;

			if (peek().type == TokenType.comma)
				eat();
		}

		return params;
	}

	void parse()
	{
		//while (index < tokens.length)
		{
			auto tk = eat();
			auto fct = new Function();
			fct.returnType = tk.getType();
			fct.name = eat().str;
			check(eat().type == TokenType.openParenthesis);
			fct.args = parseFunctionParameters();
			functions ~= fct;
		}
		functions.each!(n => n.print);
	}

	Function[] functions;

	uint index;
	Token[] tokens;
}