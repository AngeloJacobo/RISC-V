#include <stdint.h>
#include <rv32i.h>

int finish;


void __attribute__((interrupt)) trap_handler(void) {
    mtime_set_timecmp(-1);
    finish = 1;
}
int main() {
    trap_handler_setup(trap_handler); //configure MTVEC to call "trap_handler" and initially disable all interrupts 
    csr_set(MSTATUS, 1<<MSTATUS_MIE); //set global interrupt enable
    csr_set(MIE, 1<<MIE_MTIE); //set timer interrupt enable
    csr_set(MIP, 1<<MIP_MTIP); //set timer interrupt pending enable

    mtime_set_timecmp(mtime_get_time() + 1000); //set time compare to +1000 ticks of current time
    finish = 0;
    
    while(1){ //wait here until interrupt fires
        if(finish) return 0;
    }
}



