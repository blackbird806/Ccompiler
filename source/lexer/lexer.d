module lexer;
import std.container.array;
import std.regex;
import std.conv;
import std.string;
import std.array;
import std.uni : isWhite;

enum TokenType
{
    openBrace,    
    closedBrace,
    openParenthesis,
    closedParenthesis ,
    semicolon,
    returnKeyword,
    integerLiteral,
    identifier,
    undefined
}

class Token
{
    public:

    this(string str, TokenType type = TokenType.undefined)
    {
        this.str = str;
        this.type = type;
    }

    pure ulong length() const @property @safe
    {
        return str.length;
    }

    string str;
    TokenType type;
}

Token readToken(string source, ref uint index)
{
    string nsrc = source[index .. $];
    nsrc = nsrc.stripLeft();
    string word = "";
    if (nsrc.split!isWhite.length > 0)
        word = nsrc.split!isWhite[0];
    index += word.length;
    return new Token(word);
}

Array!Token lex(string source)
{
    auto tokens = Array!Token();
    uint index = 0;
    while(index <= source.length)
    {
        tokens.insertBack(readToken(source, index));
    }
    return tokens;
}
