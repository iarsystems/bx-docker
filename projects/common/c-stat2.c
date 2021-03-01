/* cstat example file. */
/* Copyright 2014-2015 IAR Systems AB. */

#pragma optimize = no_inline
char *function2(void)
{
  return 0;
}

char *function3(void)
{
  return function2();
}

char arr[10] = {0};
char function4(int i)
{
  return arr[i];
}

char function5(void)
{
  return function4(20);
}
