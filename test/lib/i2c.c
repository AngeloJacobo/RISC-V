// [REPEATED START NOT SUPPORTED]
#include <stdint.h> 
#include <rv32i.h>

volatile uint32_t *i2c_start = (volatile uint32_t *) I2C_START;
volatile uint32_t *i2c_write = (volatile uint32_t *) I2C_WRITE;
volatile uint32_t *i2c_busy = (volatile uint32_t *) I2C_BUSY;
volatile uint32_t *i2c_halt = (volatile uint32_t *) I2C_STOP;
volatile uint32_t *i2c_ack = (volatile uint32_t *) I2C_ACK;
volatile uint32_t *i2c_read_ready = (volatile uint32_t *) I2C_READ_DATA_READY;
volatile uint32_t *i2c_read = (volatile uint32_t *) I2C_READ;


// start i2c by writing slave address (returns slave ack)
uint8_t i2c_write_address(uint8_t addr){
    uint8_t ack;
    while(*i2c_busy); //stay here if busy
    *i2c_start = addr; //write to i2c address of slave
    while(*i2c_busy); //wait until write is finished
    ack = *i2c_ack; //check if slave acknowledged
    return ack;
}

// stop current i2c transaction
void i2c_stop(void){
    while(*i2c_busy);
    *i2c_halt = 0x01;
    while(*i2c_busy);
    *i2c_halt = 0x00; //set it back to zero in preparation for next transaction
    delay_ticks(100);
}

uint8_t i2c_write_byte(uint8_t data){
    uint8_t ack;
    while(*i2c_busy); //stay here if busy
    *i2c_write = data; //write data byte to slave
    while(*i2c_busy); //wait until write is finished
    ack = *i2c_ack; //check if slave acknowledged
    return ack;
}

uint8_t i2c_read_byte(){ //read a byte from the slave (after i2c_write_address())
    uint8_t read_data;
    while(*i2c_busy);
    while(*i2c_read_ready == 0){ //while read data is not yet available
    }
    read_data = *i2c_read; //retrieve data
};

