#include <stdint.h>
#include <rv32i.h>

int main(){
    int trig_pin = 0;
    int echo_pin = 1;
    int pulse_duration_us;
    int distance_cm;
    char string[16]; //max of 16 chars
    
    gpio_set_mode_pin(trig_pin, 1); //set mode setting of a single GPIO pin(read = 0, write = 1)
    gpio_set_mode_pin(echo_pin, 0); //set mode setting of a single GPIO pin(read = 0, write = 1)
    uart_print("Start Ultrasonic Sensor\n\n");
    
    while(1) {
    // set trig_pin for 10us
    gpio_write_pin(trig_pin, 0); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_us(2); // delay function based on microseconds
    gpio_write_pin(trig_pin, 1); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_us(10); // delay function based on microseconds
    gpio_write_pin(trig_pin, 0); //write to a specific GPIO pin (automatically set pin to write mode)
    
    pulse_duration_us = gpio_pulse_duration_us(echo_pin, 1); //measure how long will be the high pulse
    distance_cm = pulse_duration_us*(0.034/2); 
    
    //convert distance_cm to string
    itoa(distance_cm, string, 10);
    uart_print("Distance (cm): ");
    uart_print(string);
    uart_print("\n");
    }
    
}



