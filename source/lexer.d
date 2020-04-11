module lexer;
import std.conv;
import std.string;
import std.array;
import std.uni;
import std.stdio : writeln;

enum TokenType : uint
{
    openBrace,    
    closedBrace,
    openParenthesis,
    closedParenthesis,
    semicolon,
    comma,
    integerLiteral,
    stringLiteral,
    identifier,
    keywordInt,
    keywordReturn,
    undefined
}

enum TokenType[string] keywords = [ "int":      TokenType.keywordInt,
                                    "return":   TokenType.keywordReturn];

class Token
{
    public:

    this(string str, TokenType type = TokenType.undefined)
    {
        this.str = str;
        this.type = type;
    }

    pure ulong length() const
    {
        return str.length;
    }

    string str;
    TokenType type;
}

bool isKeyword(string name)
{
    return (name in keywords) != null;
}

bool isLanguageType(TokenType t)
{
    return cast(uint) t <=  cast(uint) TokenType.keywordInt && cast(uint) t < TokenType.keywordReturn;
}

bool isLanguageType(Token t)
{
    return isLanguageType(t.type);
}

class Lexer
{
    public:

    this(string source)
    {
        this.source = source;
    }

    Token[] lex()
    {
        auto tokens = new Token[0];
        while (index < source.length)
        {
            tokens ~= readToken();
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

    void jumpComment()
    {
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
                case ',':
                    return makeToken(current, TokenType.comma);
                case '/':
                    jumpComment();
                    break;
                case '[': case ']': 
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



