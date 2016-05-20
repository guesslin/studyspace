#include <stdio.h>

int main(int argc, const char *argv[])
{
    int a = 0;
    printf("Start ASLR program\n");
    scanf("%d", &a);
    if (a == 10) {
        a = 101;
    }
    printf("haha a is %d\n", a);
    return 0;
}
