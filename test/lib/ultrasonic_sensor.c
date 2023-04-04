#include <stdint.h>
#include <rv32i.h>

// returns distance in cm detected by the ultrasonic sensor
int ultrasonic_sensor_cm(int trig_pin, int echo_pin){
    int pulse_duration_us;
    int distance_cm;
    
    gpio_set_mode_pin(trig_pin, 1); //set mode setting of a single GPIO pin(read = 0, write = 1)
    gpio_set_mode_pin(echo_pin, 0); //set mode setting of a single GPIO pin(read = 0, write = 1)

    // set trig_pin for 10us
    gpio_write_pin(trig_pin, 0); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_us(2); // delay function based on microseconds
    gpio_write_pin(trig_pin, 1); //write to a specific GPIO pin (automatically set pin to write mode)
    delay_us(10); // delay function based on microseconds
    gpio_write_pin(trig_pin, 0); //write to a specific GPIO pin (automatically set pin to write mode)
    
    pulse_duration_us = gpio_pulse_duration_us(echo_pin, 1); //measure how long will be the high pulse
    distance_cm = pulse_duration_us*(0.034/2);  
    return distance_cm;
}





