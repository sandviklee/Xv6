#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include <stdarg.h>

int main(int argc, char *argv[])
{
    /* code */
    if (argc < 2)
    {
        hello();
    }
    else
    {
        printf("Hello %s, nice to meet you!\n", argv[1]);
    }
    return 0;
}
