/* cstat example file. */
/* Copyright 2014-2015 IAR Systems AB. */

extern char *function2(void);
extern char *function3(void);
extern char function5(void);

char *function1(void)
{
  return 0;
}

int main()
{
  char ch = 0;
  char ch1 = 1;
  volatile char r;
  
  r= ch1 /ch;
  
  ch += *function1();
  ch += *function2();
  ch += *function3();
  ch += function5();
  return 0;
}
