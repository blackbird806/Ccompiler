module parser;
import std.container.array;
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
            childrens.insertBack(n);
        }

        private:
        Token token;
        Array!Node childrens;
    }

    static class Program : Node
    {

    }

    static class FunDecl : Node
    {
        private:
        Token name;
        Token rtype;
        Array!Token argsTypes;
        Array!Token argsNames;
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
    public this(Array!Token tokenList)
    in { 
        assert(!tokenList.empty); 
    }
    body
    {
        this.tokens = tokenList;
    }

    private Token getNextToken()
    {
        return tokens[index++];
    }

    public AST parse()
    {
        AST ast = new AST();
        ast.root = new AST.Program();


        return ast;
    }

    private:

    ulong index;
    Array!Token tokens;
}
