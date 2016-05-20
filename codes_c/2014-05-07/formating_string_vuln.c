#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    char text[1024];
    static int some_value = -72;

    strcpy(text, argv[1]); /* ignore the buffer overflow here */

    printf("This is how you print correctly:\n");
    printf("%s", text);
    printf("\nThis is how not to print:\n");
    printf(text);

    printf("\nsome_value @ 0x%08x = %d [0x%08x]\n", &some_value, some_value, some_value);
    return(0);
}
