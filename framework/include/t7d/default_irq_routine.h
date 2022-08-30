
extern volatile unsigned long framecounter;

extern volatile void(*irq_routine_funpointer)(void);

/*! \brief Setup the default interrupt routine
 *
 * The default interrupt routine checks for the mouse button and irqfun once per frame
 *
 * \param initfun called once before anything else
 * \param entry called to start the demo (with enabled interrupts)
 * \param irqfun called once per frame
 */
void set_irq_routine(void(*initfun)(void), void (*entryfun)(void), void (*irqfun)(void));

/*! \brief set the IRQ routine function pointer to be called
 *
 * At each frame this function is called. This replaces the old stored function pointer as optimisation tends to ignore the volatile sometimes. So we burn 32 cycles.
 *
 * \param irqfun function to be called from irq every frame
 * \returns old function pointer
 */
void *set_irq_routine_funpointer(__reg("a0") void(*irqfun)(void));
