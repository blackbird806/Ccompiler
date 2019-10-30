module parser;
import std.stdio;
import lexer;

class AST
{
    public:

    static class Node
    {
        public:

        void addChild(Node n)
        {
            childrens ~= n;
        }

        Node[] childrens;
        private:
    }

    static class Program : Node
    {

    }

    static class Argument : Node
    {
        public:
        Token type;
        Token name;
    }

    static class FunDecl : Node
    {
        public:
        Token name;
        Token rtype;
        Argument[] args;
    }

    static class FunBody : Node
    {
    }

    static class Statement : Node
    {
    }

    static class Constant : Node
    {
    }

    private void printChildren(const Node n) const
    {
        foreach(child; n.childrens) 
        {
            writeln(typeid(child));
            printChildren(child);
        }
    }

    void print() const
    {
        printChildren(root);
    }

    Node root;
}

class Parser
{
    public this(Token[] tokenList)
    {
        this.tokens = tokenList;
    }

    private Token getNextToken()
    {
        return tokens[index++];
    }

    private Token currentToken() @property
    {
        return tokens[index-1];
    }

    private AST.Argument isArgument()
    {
        auto arg = new AST.Argument;
        arg.type = getNextToken();
        arg.name = getNextToken();

        if  (!arg.type.isLanguageType())
            return null;

        if (arg.name.type != TokenType.identifier)
        {
            arg.name = null;
            index--;
        }

        return arg;
    }

    // return null if false
    private AST.FunDecl isFuncDef()
    {
        AST.FunDecl fun = new AST.FunDecl;
        fun.rtype = getNextToken();
        fun.name = getNextToken();
        auto openParenthesis = getNextToken();
        if  (   !fun.rtype.isLanguageType()             &&
                fun.name.type != TokenType.identifier   &&
                openParenthesis.type != TokenType.openParenthesis)
        {
                return null;
        }
        
        while (currentToken.type != TokenType.closedParenthesis)
        {
            auto arg = isArgument();
            if (arg is null)
                break;
            fun.args ~= arg;
            if (getNextToken().type != TokenType.comma && currentToken.type != TokenType.closedParenthesis)
                return null;
        }

        return fun;
    }

    public AST parse()
    {
        AST ast = new AST();
        ast.root = new AST.Program();
        auto current = ast.root;
        // while (index <= tokens.length)
        {
            auto fn = isFuncDef();
            assert(fn !is null);
            
            writeln(fn.rtype.str, " ", fn.name.str);
            foreach(p; fn.args)
            {
                writeln(p.type.str);
                writeln(p.name.str);
            }
        }

        return ast;
    }

    invariant()
    {
        assert(index <= tokens.length);
    }

    private:

    ulong index;
    Token[] tokens;
}
