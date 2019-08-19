
#define OWN_libraries 1
#define OWN_view 2
#define OWN_trap 4
#define OWN_interrupt 8

void *own_machine(unsigned long bitmask);
void disown_machine(void);
