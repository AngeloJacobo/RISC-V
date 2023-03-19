#include <stdint.h> 
#include <rv32i.h>

int main() {
    i2c_write_address(0xaa);
    i2c_write_byte('A');
    i2c_write_byte('Z');
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

