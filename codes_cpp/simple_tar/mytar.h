#ifndef MYTAR_H
#define MYTAR_H

#ifdef __DEBUG__
#define CERR(fmt, arg...) fprintf(stderr, fmt, ## arg)
#else
#define CERR()
#endif


#include <fstream>
#include <list>

using namespace std;

struct Tarfile{
public:
	char filename[100];
	char filemode[8];
	char userid[8];
	char groupid[8];
	char filesize[12];
	char mtime[12];
	char checksum[8];
	char type;
	char lname[100];
	/* USTAR Section */
	char USTAR_id[6];
	char USTAR_ver[2];
	char username[32];
	char groupname[32];
	char devmajor[8];
	char devminor[8];
	char prefix[155];
	char pad[12];
}__attribute__ ((packed));

class Mytar{
public:
	Mytar(char *fpath);
	Mytar();
	~Mytar();

	int fetch();
	bool isustar(char *id);
	int output();
	int oct2dec(int o);
	int counter();
private:
	ifstream in;
	int count;
	list<Tarfile> tptr;
};

#endif
/* vim:ts=4
 */
