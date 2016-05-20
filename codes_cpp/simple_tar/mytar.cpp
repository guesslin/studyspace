#include <iostream>
#include <fstream>
#include <iomanip>
#include <cstring>
#include <cmath>
#include <list>
#include <cstdlib>
#include "mytar.h"

using namespace std;

Mytar::Mytar(): count(0)
{
	char tmp[100];
	cerr<<"Please Input filename/path: ";
	cin>>tmp;
	in.open(tmp);
}

Mytar::Mytar(char *fpath): count(0)
{
	in.open(fpath);
}

Mytar::~Mytar()
{
	in.close();
}

bool Mytar::isustar(char *id)
{
	char ustar[]="ustar";
	int cmp = strncmp(ustar, id, 5);
	if (!cmp)
		return true;
	return false;
}

int Mytar::oct2dec(int o)
{
	int d = 0, i = 1;
	d=1*(o%10);
	o-=o%10;
	o=o/10;
	while(o!=0)
	{
		d+=static_cast<int>(pow(8.0,i))*(o%10);
		o-=o%10;
		o=o/10;
		++i;
	}
	return d;
}

int Mytar::counter()
{
	Tarfile tmpf;
	count = 0;
	int c = 0, o = 0;
	size_t mov = 0;
	if (in.fail()) {
		cerr<<"FILE DO NOT EXIST!!"<<endl;
		exit(-1);
	}

	in.seekg(0, ios::beg);
	in.read(reinterpret_cast<char *> (&tmpf), 512);
	
	if (!isustar(tmpf.USTAR_id)) {
		cerr<<"NOT A USTAR FILE!"<<endl;
		exit(-1);
	}
	
	in.seekg(0, ios::beg);
	
	while (!in.eof()) {
		in.read(reinterpret_cast<char *> (&tmpf), 512);
	
		if (!isustar(tmpf.USTAR_id)) {
			return count;
		}
		
		tptr.push_back(tmpf);
		o = atoi(tmpf.filesize);
		mov = oct2dec(o);
		c = mov % 512;
		if(c != 0)
			mov = mov+512-c;
		if (mov != 0)
			in.seekg(mov, ios::cur);
		++count;
	}
	return count;
}

int Mytar::fetch()
{
	counter();
	return count;
}

int Mytar::output()
{
	int filesz = 0, color = 37;
	cout<<"Total "<<count<<" files.\n";
	for ( list<Tarfile>::iterator ite = tptr.begin();
						ite != tptr.end(); ++ite) {
		switch (ite->type) {
		case '1':
		case '2':
			cout<<"l";
			color = 36;
			break;
		case '3':
			cout<<"c";
			color = 33;
			break;
		case '4':
			cout<<"b";
			color = 33;
			break;
		case '5':
			cout<<"d";
			color = 34;
			break;
		case '6':
			cout<<"p";
			color = 32;
			break;
		case '7':
			cout<<"C";
			color = 31;
			break;
		default:
			cout<<"-";
			color = 37;
			break;
		}
		for (int j=4; j<=6; j++) {
	        switch (ite->filemode[j]) {
            case '0':
                cout<<"---";
                break;
            case '1':
                cout<<"--x";
                break;
            case '2':
                cout<<"-w-";
                break;
            case '3':
                cout<<"-wx";
                break;
            case '4':
                cout<<"r--";
                break;
            case '5':
                cout<<"r-x";
                break;
            case '6':
                cout<<"rw-";
                break;
            case '7':
                cout<<"rwx";
                break;
        	}
		}
        cout<<" "<<ite->username<<"/"<<ite->groupname<<" ";
		cout.setf(ios::right);
		cout.width(9);
		filesz = atoi(ite->filesize);
		filesz = oct2dec(filesz);
		cout<<filesz<<" ";
		switch (color) {
		case 31:
			cout<<"\033[1;31m";
			break;
		case 32:
			cout<<"\033[1;32m";
			break;
		case 33:
			cout<<"\033[1;33m";
			break;
		case 34:
			cout<<"\033[1;34m";
			break;
		case 35:
			cout<<"\033[1;35m";
			break;
		case 36:
			cout<<"\033[1;36m";
			break;
		default:
			cout<<"\033[0;37m";
			break;
		}
		cout<<ite->filename<<"\033[m";
		if (ite->type == '1' || ite->type == '2' ) {
			cout<<" -> \033[1;36m"<<ite->lname;
		}
		cout<<"\033[m"<<endl;
	}
	return 0;
}
