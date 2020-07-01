void main()
{
	int a;
	a = 0;
	while (a < 100)
	{
		a = a + 1;
		print a;
	}

	int n;
	int num;
	int b;

	num = 5;
	b = num;
	n = 4;

	int i;
	for (i=0; i < n-1; i = i + 1)
	{
		num = num * b;
	}
	print num;
}