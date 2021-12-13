void main()
{
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

