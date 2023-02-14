#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// return hello statement hello world
// Added as a lab1 excercise.

uint64
sys_hello(void)
{
  printf("Hello World\n");
  return 22;
}

uint64
sys_procState(void)
{
  static const char *stateString[] = {
      "UNUSED", "USED", "SLEEPING", "RUNNABLE", "RUNNING", "ZOMBIE"};
  printf("PID: %d\n", myproc()->pid);
  int i = myproc()->state;
  printf("State: %s\n", stateString[i]);

  return 23;
}

// Prints arrays
uint64
sys_prarr(char *array[])
{
  int count = strlen(*array);
  for (int i = 0; i < count; i++)
  {
    /* code */
    // printf("%s\n", array[i]);
    printf("%d\n", count);
  }

  return 24;
}

// Prints the ongoing system processes
uint64
sys_ps(void)
{
  proctest();
  return 25;
}