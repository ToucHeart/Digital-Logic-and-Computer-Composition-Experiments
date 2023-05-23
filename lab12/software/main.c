#include "sys.h"

char hello[] = "Hello World!";
char hello2[] = "hello";
char time[] = "time";
char fibstr[] = "fib";
char buf[100];
char unknown[] = "Unknown Command!";
char clear[] = "clear";

int *q = (int *)0x00500000;
int printLineNumber = 0;
int readptr = 0;
int storageNum = 0;
extern int vgaLinenum;
extern int vga_ch;
extern char *vga_start;
extern int flag;

int main();

// setup the entry point
void entry()
{
    asm("lui sp, 0x00120"); // set stack to high address of the dmem
    asm("addi sp, sp, -4");
    main();
}

void vga_init()
{
    vga_ch = 2;
    printLineNumber = 0;
    vgaLinenum = 0;
    readptr = 0;
    storageNum = 0;
    flag = 1;

    for (int j = 2; j < 4096; j++)
    {
        vga_start[j] = 0;
    }
    vga_start[0] = 0x7E;
    vga_start[1] = 0x24;
}

void timer()
{
    int p = *(int *)0x00400000; // 10'b0,hour,2'b0,minute,2'b0,second

    char *secptr = (char *)&p;
    unsigned int sec = (int)(*(secptr));

    char *minptr = (secptr + 1);
    unsigned int min = (int)(*(minptr));

    char *hourptr = (secptr + 2);
    unsigned int hour = (int)(*(hourptr));

    if (hour < 10)
        putch('0');
    printInt(hour);
    putch(':');
    if (min < 10)
        putch('0');
    printInt(min);
    putch(':');
    if (sec < 10)
        putch('0');
    printInt(sec);
}
int mystrcmp(const char *a, int size)
{
    int i = 0;
    while (a[i] != '\0' && buf[i] == a[i] && i < size)
        i++;
    if (size == i)
        return 1;
    return 0;
}
int str2int(char *str, int i)
{
    int ans = 0;
    while (str[i] != '\0' && i < storageNum)
    {
        if (str[i] >= '0' && str[i] <= '9')
        {
            ans = ans * 10;
            ans += str[i] - '0';
            ++i;
        }
        else
            return -1;
    }
    return ans;
}
void roll()
{
    if (vgaLinenum >= 2100)
    {
        printLineNumber += 1;
        if (printLineNumber == 28)
        {
            vga_init();
        }
        (*q) = printLineNumber;
    }
}
void caller()
{
    if (storageNum == 0)
    {
        vga_ch = 2;
    }
    else if (storageNum == 5 && mystrcmp(hello2, 5))
    {
        vga_ch = 0;
        putstr(hello);
        roll();
        vgaLinenum += 70;
    }
    else if (storageNum == 4 && mystrcmp(time, 4))
    {
        vga_ch = 0;
        timer();
        roll();
        vgaLinenum += 70;
    }
    else if (storageNum >= 3 && mystrcmp(fibstr, 3))
    {
        vga_ch = 0;
        int i = 3;
        while (buf[i] == 0x20)
        {
            i++;
        }
        int temp = str2int(buf, i);
        if (temp == -1)
        {
            vga_ch = 0;
            putstr(unknown);
            roll();
        }
        else
        {
            fib(temp);
            roll();
        }
        vgaLinenum += 70;
    }
    else if (storageNum != 0)
    {
        vga_ch = 0;
        putstr(unknown);
        roll();
        vgaLinenum += 70;
    }
    vga_start[vgaLinenum] = 0x7E;
    vga_start[vgaLinenum + 1] = 0x24;
    vga_ch = 2;
    for (int i = 0; i < storageNum; ++i)
        buf[i] = 0;
}

int main()
{
    vga_init();
    char *c = (char *)0x00300000;
    while (1)
    {
        if (readptr == 16)
            readptr = 0;
        char ch = *(c + readptr);
        if (ch != 0)
        {
            if (ch == 0x0D) // enter
            {
                vgaLinenum += 70;
                caller();
                roll();
                storageNum = 0;
                readptr++;
                flag = 1;
            }
            else if (ch == 8) // backspace
            {
                if (vga_ch == 2 && flag) //&& vga_start[vgaLinenum] == 0x7E) // head of line
                {
                }
                else if (vga_ch == 0)
                {
                    vga_ch = 69;
                    vgaLinenum -= 70;
                    vga_start[vgaLinenum + vga_ch] = 0;
                    storageNum--;
                    flag = 1;
                }
                else
                {
                    vga_ch--;
                    vga_start[vgaLinenum + vga_ch] = 0;
                    storageNum--;
                }
                readptr++;
            }
            else
            {
                putch(ch);
                buf[storageNum++] = ch;
                readptr++;
            }
        }
    };
    return 0;
}
