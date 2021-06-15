#include "print.h"
#include "init.h"
#include "memory.h"
#include "thread.h"
#include "interrupt.h"

void k_thread_a(void *);
void k_thread_b(void *);


int main(void)
{
	put_str("invoke main[kernel init]\n");

	init_all();

	// 允许中断发生                  cli表示禁止中断发生
	// asm volatile("sti");

	void *addr = get_kernel_pages(3);
	put_str("\nget_kernel_pages start vaddr = 0x");
    put_int((uint32_t)addr);
    put_str("\n\n");


    thread_start("k_thread_a", 31, k_thread_a, "argA");
    thread_start("k_thread_b", 8, k_thread_b, "argB");

    intr_enable();


	// 允许中断发生                  cli表示禁止中断发生
	// asm volatile("sti");

    // while(1);

	while (1)
	{
		put_str("main ");
	}

	return 0;
}


void k_thread_a(void *arg)
{
	char *pArg = arg;
	while (1)
	{
		put_str(pArg);
	}
}
void k_thread_b(void *arg)
{
	char *pArg = arg;
	while (1)
	{
		put_str(pArg);
	}
}