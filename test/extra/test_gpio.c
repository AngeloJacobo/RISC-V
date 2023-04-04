#include <stdint.h>
#include <rv32i.h>

int main(){
    int counter = 0;
    gpio_write_pin(10, 1); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_ticks(100); //after 100 cpu clock ticks
    gpio_write_pin(10, 0); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_ticks(100); //after 100 cpu clock ticks
    gpio_write_pin(10, 1); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_ticks(100); //after 100 cpu clock ticks
    /*while(1)*/{
        toggle_gpio(5); //toggle a specific GPIO pin (automatically set pin to write mode)
        delay_ticks(100); //after 100 cpu clock ticks
    }
}
