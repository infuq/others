#include<stdio.h>

/*
结构体内存对齐
*/

struct Stu
{
    char c;
    int year;
    char k;
};


struct Tch
{
    char k;
    char c;
    int year;
};

int main()
{

    printf("%d\n", sizeof(struct Stu));//12

    printf("%d\n", sizeof(struct Tch));//8

    return 0;
}