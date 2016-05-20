#include <iostream>

#define cube(x) x*x*x

class cube
{
	public:
		int test;
};

int main(void)
{
	cube a;
	a.test = 10;
	std::cout<<cube(a.test);
	std::cin.ignore();
	return 0;
}
