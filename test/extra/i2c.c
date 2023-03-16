#include <stdint.h> 

#define I2C_START 8040 
#define I2C_WRITE 8044
#define I2C_READ 8048
#define I2C_BUSY 8052
#define I2C_ACK 8056
#define I2C_READ_DATA_READY 8060
#define I2C_STOP 8064

#define UART_TX_DATA_ADDR 8140
#define UART_TX_BUSY_ADDR 8144

volatile uint32_t *i2c_start = (volatile uint32_t *) I2C_START;
volatile uint32_t *i2c_write = (volatile uint32_t *) I2C_WRITE;
volatile uint32_t *i2c_busy = (volatile uint32_t *) I2C_BUSY;
volatile uint32_t *i2c_halt = (volatile uint32_t *) I2C_STOP;
volatile uint32_t *i2c_ack = (volatile uint32_t *) I2C_ACK;

volatile uint32_t *uart_tx_data = (volatile uint32_t *) UART_TX_DATA_ADDR;
volatile uint32_t *uart_tx_busy = (volatile uint32_t *) UART_TX_BUSY_ADDR;


void wait_cycles(uint32_t num_cycles) {
    for(uint32_t i =0; i<num_cycles;i++) {
        __asm__("nop");
    }
}

uint8_t i2c_write_address(uint8_t addr){
    uint8_t ack;
    while(*i2c_busy); //stay here if busy
    *i2c_start = addr; //write to i2c address of slave
    while(*i2c_busy); //wait until write is finished
    ack = *i2c_ack; //check if slave acknowledged
    return ack;
}

void i2c_stop(){
    while(*i2c_busy);
    *i2c_halt = 0x01;
    while(*i2c_busy);
    *i2c_halt = 0x00; //set it back to zero in preparation fot next transaction
    wait_cycles(100);
}

uint8_t i2c_write_byte(uint8_t data){
    uint8_t ack;
    while(*i2c_busy); //stay here if busy
    *i2c_write = data; //write data byte to slave
    while(*i2c_busy); //wait until write is finished
    ack = *i2c_ack; //check if slave acknowledged
    return ack;
}

void uart_print(char *message) {
    int i = 0;
    while (message[i] != '\0') {
        while (*uart_tx_busy);  // wait for UART to be ready
        *uart_tx_data = message[i];
        i++;
    }
}
int main() {

    while(*i2c_busy); //stay while i2c is busy
    *i2c_start = 0xaa;
    while(*i2c_busy);
    *i2c_write = 0x01;
    while(*i2c_busy);
    wait_cycles(1000);
    *i2c_write = 0xF1;
    while(*i2c_busy);
    i2c_stop();
    return 0;
    
    
    /* I2C Address Finder
    uart_print("\n\nSTART THE I2C ADDRES FINDER\n\n");
    int address;
    uint8_t ack; 
    for(address=1; address<128; address++){ 
        ack = i2c_write_address(address<<1); //rightmost bit is 0(write)
        i2c_stop(); //make sure to stop before accessing new address slave
        if(ack){
            uart_print("\nFound the address:");
            //char str_address[20];
           // sprintf(str_address,"%d",address);
            //uart_print(str_address);
            uart_print("\n\n\n\n");
        } 
        else{
            uart_print("\nWRONG:");
            //char str_address[20];
            //sprintf(str_address,"%d",address);
            //uart_print(str_address);
        }
    }

    return 0;
    */    
}

