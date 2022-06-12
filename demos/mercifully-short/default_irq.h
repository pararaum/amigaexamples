#define WAITFRAMES(x)   irqcounter = x; while(irqcounter > 0) {}

extern volatile long irqcounter;

extern void (*irqVBLroutine)(void); //!< pointer to the interrupt routine.
extern void install_enable_IRQ(void);

