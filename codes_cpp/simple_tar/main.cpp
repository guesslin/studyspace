#include <iostream>
#include <fstream>
#include <iomanip>

#include "mytar.h"

using namespace std;

int main(int argc, char *argv[])
{
	Mytar tar(argv[1]);
	tar.fetch();
	tar.output();
	return 0;
}
