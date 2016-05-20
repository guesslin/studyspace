#include <stdio.h>

char* genkey() {
	int v3 = 10;
	while ( v3 )
	{
		if ( isalnum(*(_BYTE *)v4 & 0x7F) )
		{
			if ( read(0, &buf, 1u) == 1 && buf != (*(_BYTE *)v4 & 0x7F) )
				return 1;
			--v3;
		}
		v4 = (int (*)(void))((char *)v4 + 1);
	}
}
