
extern volatile unsigned long framecounter;
extern void(*irq_routine_funpointer)(void);
void set_irq_routine(void(*initfun)(void), void (*entryfun)(void), void (*irqfun)(void));
