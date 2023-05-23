
#include "sys.h"

//#define VGA_START    0x00200000
//#define VGA_LINE_O   0x00210000
//#define VGA_MAXLINE  30
//#define LINE_MASK    0x003f
//#define VGA_MAXCOL   70

char *vga_start = (char *)VGA_START;
int vga_ch = 0;
int vgaLinenum = 0;
int flag = 1;
unsigned int mulsi3(unsigned int a, unsigned int b) //乘法
{
    unsigned int r = 0;

    while (a)
    {
        if (a & 1)
            r += b;
        a >>= 1;
        b <<= 1;
    }
    return r;
}

unsigned int umodsi3(unsigned int a, unsigned int b) //取模
{
    unsigned int bit = 1;
    unsigned int res = 0;

    while (b < a && bit && !(b & (1UL << 31)))
    {
        b <<= 1;
        bit <<= 1;
    }
    while (bit)
    {
        if (a >= b)
        {
            a -= b;
            res |= bit;
        }
        bit >>= 1;
        b >>= 1;
    }
    return a;
}

unsigned int udivsi3(unsigned int a, unsigned int b)
{
    unsigned int bit = 1;
    unsigned int res = 0;

    while (b < a && bit && !(b & (1UL << 31)))
    {
        b <<= 1;
        bit <<= 1;
    }
    while (bit)
    {
        if (a >= b)
        {
            a -= b;
            res |= bit;
        }
        bit >>= 1;
        b >>= 1;
    }
    return res;
}
void printInt(unsigned int n)
{
    if (n == 0)
    {
        putch(0x30);
        return;
    }
    char ansStr[21];
    unsigned int len = 0;
    while (n)
    {
        ansStr[len++] = umodsi3(n, 10) + 0x30;
        n = udivsi3(n, 10);
    }
    // ans to string
    char temp;
    for (unsigned int j = 0; j <= udivsi3((len - 1), 2); j++)
    {
        temp = ansStr[j];
        ansStr[j] = ansStr[len - j - 1];
        ansStr[len - j - 1] = temp;
    }
    ansStr[len] = '\0';
    // print
    putstr(ansStr);
}

void fib(int n)
{
    // compute ans
    unsigned int ans;
    if (n <= 2)
        ans = 1;
    unsigned int last1 = 1;
    unsigned int last2 = 1;
    for (int i = 3; i <= n; i++)
    {
        ans = last1 + last2;
        last2 = last1;
        last1 = ans;
    }
    printInt(ans);
}

void vga_init()
{
    vga_ch = 2;
    vga_start[0] = 0x7E;
    vga_start[1] = 0x24;
    int n = 70;
    for (int k = 2; k < VGA_MAXCOL; ++k)
        vga_start[k] = 0;
    for (int i = 1; i < VGA_MAXLINE; i++)
    {
        for (int j = 0; j < VGA_MAXCOL; j++)
        {
            vga_start[n + j] = 0;
        }
        n = n + 70;
    }
}

void putch(char ch)
{
    vga_start[vgaLinenum + vga_ch] = ch;
    vga_ch++;
    if (vga_ch >= VGA_MAXCOL)
    {
        vgaLinenum += 70;
        vga_ch = 0;
        flag = 0;
    }
    return;
}

void putstr(char *str)
{
    for (char *p = str; *p != 0; p++)
        putch(*p);
}
