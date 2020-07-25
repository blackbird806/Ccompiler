#define DECLARE_A int a;
#define func void
#define SEMI ;
#define PRINT print
#define NOP

func main()
{
	NOP
	DECLARE_A
	a = 5 SEMI
	int b;
	b = a - 1;
	PRINT a;
}