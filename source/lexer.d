module lexer;
import std.container.array;
import std.conv;
import std.string;
import std.array;
import std.uni;
import std.stdio : writeln;

enum TokenType
{
    openBrace,    
    closedBrace,
    openParenthesis,
    closedParenthesis,
    semicolon,
    integerLiteral,
    identifier,
    keywordInt,
    keywordReturn,
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

bool isKeyword(string name)
{
    switch(name)
    {
        case "int": case "return":
            return true;
        default:
            return false;
    }
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

    // read indent or keyword
    Token readIdentOrKeyword()
    {
        auto tmp = index;
        while(source[index].isAlphaNum || source[index] == '_')
            index++;
        immutable string name = source[tmp .. index];
        if (isKeyword(name))
            return new Token(name, to!TokenType("keyword" ~ cast(char) name[0].toUpper ~ name[1 .. $]));
        return new Token(name, TokenType.identifier);
    }

    // make token from char
    Token makeToken(char c, TokenType t = TokenType.undefined)
    {
        index++;
        return new Token(to!string(c), t);
    }

    // read decimal number
    Token readNumberDec()
    {
        auto tmp = index;
        while (source[index].isNumber)
            index++;
        return new Token(source[tmp .. index], TokenType.integerLiteral);
    }

    Token readToken()
    {
        while (index < source.length)
        {
            immutable char current = source[index];
            switch(current)
            {
                case 'a': .. case 'z':
                case 'A': .. case 'Z':
                    return readIdentOrKeyword();
                case '0': .. case '9':
                    return readNumberDec();
                case '(':
                    return makeToken(current, TokenType.openParenthesis); 
                case ')': 
                    return makeToken(current, TokenType.closedParenthesis); 
                case '{':
                    return makeToken(current, TokenType.openBrace); 
                case '}':
                    return makeToken(current, TokenType.closedBrace); 
                case ';':
                    return makeToken(current, TokenType.semicolon); 
                case ',':  case '[': case ']': 
                 case '?': case '~': case '=':
                return makeToken(current);
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



