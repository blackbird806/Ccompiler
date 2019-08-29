module lexer;
import std.container.array;
import std.conv;
import std.string;
import std.array;
import std.uni : isWhite, isAlphaNum;
import std.stdio : writeln;

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

class Lexer
{
    public:

    this(string source)
    {
        this.source = source;
    }

    Array!Token lex()
    {
        auto tokens = Array!Token();
        while (index < source.length)
        {
            tokens.insertBack(readToken());
        }
        return tokens;
    }

    private:

    Token readIdent()
    {
        auto tmp = index;
        while(source[index].isAlphaNum)
        {
            index++;
        }
        return new Token(source[tmp .. index]);
    }

    Token readToken()
    {
        while (index < source.length)
        {
            switch(source[index])
            {
                case 'a': .. case 'z':
                    return readIdent();

                default:
                    index++;
                break;
            }
        }
        return null;
    }

    string source;
    ulong index;
}



