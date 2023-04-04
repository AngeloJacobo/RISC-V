#include <stdint.h>
#include <rv32i.h>

volatile uint32_t *gpio_mode_reg = (volatile uint32_t *) GPIO_MODE;
volatile uint32_t *gpio_write_reg = (volatile uint32_t *) GPIO_WRITE;
volatile uint32_t *gpio_read_reg = (volatile uint32_t *) GPIO_READ;

//read mode setting of the GPIOs (read = 0, write = 1)
uint32_t gpio_read_mode(){
    return *gpio_mode_reg;
}

//set mode setting og the GPIOs (read = 0, write = 1)
void gpio_set_mode(uint32_t mode){
    *gpio_mode_reg = mode;
}

//write to GPIOs
void gpio_write(uint32_t write){
    *gpio_write_reg = write;
}

//read current write value of GPIOs
uint32_t gpio_write_value(){
    return *gpio_write_reg;
}

//read GPIO
uint32_t gpio_read(){
    return *gpio_read_reg;
}

//toggle a specific GPIO pin
void toggle_gpio(uint32_t pin_number){
    gpio_set_mode_pin(pin_number, 1); //set pin to write mode
    uint32_t value;
    value = gpio_write_value(); //read current write value 
    gpio_write(value ^ (1<<pin_number)); //reverse the value of the pin
}

//write to a specific GPIO pin
void gpio_write_pin(uint32_t pin_number, uint32_t val){
    gpio_set_mode_pin(pin_number, 1); //set pin to write mode
    uint32_t value;
    value = gpio_write_value(); //read current write value 
    if(val) gpio_write(value | (1<<pin_number)); //set the pin high
    else gpio_write(value & (~(1<<pin_number))); //set the pin low
}

//read a specific GPIO pin
uint32_t gpio_read_pin(uint32_t pin_number){
    gpio_set_mode_pin(pin_number, 0); //set pin to read mode
    uint32_t value;
    value = gpio_read();
    if(value & (1<<pin_number)){
        return 1;
    }
    else{
        return 0;
    }
}


//set mode setting of a single GPIO pin(read = 0, write = 1)
void gpio_set_mode_pin(uint32_t pin_number, uint32_t mode){
    uint32_t all_modes = gpio_read_mode();
    if(mode){ //write
        gpio_set_mode(all_modes | (1<<pin_number));
    }
    else{ //read
        gpio_set_mode(all_modes & (~(1<<pin_number)));
    }
}

//measure pulse duration of a GPIO pin in us
uint32_t gpio_pulse_duration_us(uint32_t pin_number, uint32_t val){
    uint64_t time;

    while(gpio_read_pin(pin_number) != val); //wait until pin value becomes val
    time = mtime_get_time(); //record time
    while(gpio_read_pin(pin_number) == val);// wait until pin value changes
    time = (uint32_t) (mtime_get_time() - time); 
    return cpu_ticks_to_us(time); // convert cpu clock ticks to us
}







