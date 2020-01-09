
extern unsigned long framecounter;
void set_irq_routine(void(*initfun)(void), void (*entryfun)(void));
