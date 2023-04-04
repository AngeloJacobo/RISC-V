#include <stdint.h>

// I2C memory-mapped registers
#define I2C_START 0x800000A0
#define I2C_WRITE 0x800000A4
#define I2C_READ 0x800000A8
#define I2C_BUSY 0x800000AC
#define I2C_ACK 0x800000B0
#define I2C_READ_DATA_READY 0x800000B4
#define I2C_STOP 0x800000B8

// UART memory-mapped registers
#define UART_TX_DATA 0x80000050
#define UART_TX_BUSY 0x80000054
#define UART_RX_BUFFER_FULL 0x80000058
#define UART_RX_DATA 0x8000005C

//GPIO memory-mapped registers
#define GPIO_MODE 0x800000F0
#define GPIO_READ 0x800000F4
#define GPIO_WRITE 0x800000F8

// CLINT memory-mapped registers
#define CPU_CLK_HZ 12000000
#define MTIME_BASE_ADDRESS 0x80000000
#define MTIMECMP_BASE_ADDRESS 0x80000008
#define MSIP_BASE_ADDRESS 0x80000010

// Registers used in HygroPMOD
#define HYGROI2C_I2C_ADDR   0x40
#define HYGROI2C_TMP_REG    0x00
#define HYGROI2C_HUM_REG    0x01
#define HYGROI2C_CONFIG_REG 0x02

// Control Status Registers
#define MARCHID 0xF12
#define MIMPID 0xF13
#define MHARTID 0xF14
#define MSTATUS 0x300 
#define MISA 0x301
#define MIE 0x304
#define MTVEC 0x305
#define MSCRATCH 0x340 
#define MEPC 0x341
#define MCAUSE 0x342
#define MTVAL 0x343
#define MIP 0x344
#define MCYCLE 0xB00
#define MCYCLEH 0xB80
#define TIME 0xC01
#define TIMEH 0xC81
#define MINSTRET 0xB02
#define MINSTRETH 0xBB2
#define MCOUNTINHIBIT 0x320

#define MSTATUS_MIE 3
#define MIP_MSIP 3
#define MIP_MTIP 7
#define MIP_MEIP 11
#define MIE_MSIE 3
#define MIE_MTIE 7
#define MIE_MEIE 11

// LCD cpnfigurations
#define LCD_I2C_ADDR 0x27 
#define LCD_BACKLIGHT 0x08
#define LCD_NOBACKLIGHT 0x00
#define LCD_FIRST_ROW  0x80
#define LCD_SECOND_ROW 0xC0
#define LCD_THIRD_ROW 0x94
#define LCD_FOURTH_ROW 0xD4
#define LCD_CLEAR 0x01
#define LCD_RETURN_HOME 0x02
#define LCD_ENTRY_MODE_SET 0x04
#define LCD_CURSOR_OFF 0x0C
#define LCD_UNDERLINE_ON 0x0E
#define LCD_BLINK_CURSOR_ON 0x0F
#define LCD_MOVE_CURSOR_LEFT 0x10
#define LCD_MOVE_CURSOR_RIGHT 0x14
#define LCD_TURN_ON 0x0C
#define LCD_TURN_OFF 0x08
#define LCD_SHIFT_LEFT 0x18
#define LCD_SHIFT_RIGHT 0x1E
#define LCD_TYPE 2 // 0 -> 5x7 | 1 -> 5x10 | 2 -> 2 lines

// Function prototypes for clint.c
void mtime_set_time(uint64_t time); // set current system time.
uint64_t mtime_get_time(void) ; // return current system time.
void mtime_set_timecmp(uint64_t timecmp); // set compare time register (generates timer interrupts when mtime>=mtimecmp)
uint64_t mtime_get_timecmp(void); // Get compare time register 
void trap_handler_setup(void (*trap_handler)(void)); //setup trap handler by setting MTVEC and initially disabling all interrupts (NOTE: trap handler function MUST HAVE ATTRIBUTE INTERRUPT)
void enable_software_interrupt(void); // trurn on software interrupt
void disable_software_interrupt(void); // turn off software interrupt
uint64_t ms_to_cpu_ticks (uint64_t ms); // convert milliseconds input to cpu clock ticks
void delay_ms(uint64_t ms); // delay function based on milliseconds
void delay_ticks(uint32_t ticks); // delay function based on cpu clock tick
void delay_us(uint64_t us); // delay function based on microseconds
uint32_t cpu_ticks_to_us (uint64_t ticks); // convert cpu clock ticks to us

// Inline functions go to header file
static inline void __attribute__ ((always_inline)) csr_set(const int csr_id, uint32_t mask) { // set bits in CSR
  uint32_t csr_data = mask;
  asm volatile ("csrs %[input_i], %[input_j]" :  : [input_i] "i" (csr_id), [input_j] "r" (csr_data));
}
inline void __attribute__ ((always_inline)) csr_write(const int csr_id, uint32_t data) { // write to csr
  uint32_t csr_data = data;
  asm volatile ("csrw %[input_i], %[input_j]" :  : [input_i] "i" (csr_id), [input_j] "r" (csr_data));
}

// Function prototypes for i2c.c [[REPEATED START NOT SUPPORTED]]
uint8_t i2c_write_address(uint8_t addr); // start i2c by writing slave address (returns slave ack)
void i2c_stop(void); // stop current i2c transaction
uint8_t i2c_write_byte(uint8_t data); // write to slave (returns slave ack) (after i2c_write_address())
uint8_t i2c_read_byte(); //read a byte from the slave (after i2c_write_address())

// Function prototypes for uart.c
void uart_print(char *message); // print characters serially via UART
int uart_rx_buffer_full(); //check if read buffer is full and data can be read
char uart_read(); //read data from buffer (make sure to check first if rx buffer is full)

// Function prototypes for gpio.c
void toggle_gpio(uint32_t pin_number); //toggle a specific GPIO pin (automatically set pin to write mode)
void gpio_set_mode_pin(uint32_t pin_number, uint32_t mode); //set mode setting of a single GPIO pin(read = 0, write = 1)
void gpio_write_pin(uint32_t pin_number, uint32_t val); //write to a specific GPIO pin (automatically set pin to write mode)
uint32_t gpio_read_pin(uint32_t pin_number); //read a specific GPIO pin
uint32_t gpio_pulse_duration_us(uint32_t pin_number, uint32_t val); //measure pulse duration of a GPIO pin in us
uint32_t gpio_read_mode(); //read mode setting of the GPIOs (read = 0, write = 1)
void gpio_set_mode(uint32_t mode); //set mode setting og the GPIOs (read = 0, write = 1)
void gpio_write(uint32_t write); //write to GPIOs
uint32_t gpio_write_value(); //read current write value of GPIOs
uint32_t gpio_read(); //read GPIO

// Function prototypes for lcd.c
void LCD_Init(); //initialize LCD with proper routine
void LCD_Set_Cursor(unsigned char ROW, unsigned char COL); //Set cursor where to start writing to LCD
void LCD_Write_String(char*); //write string to LCD
void Backlight(void); //turn on backlight (initially turned on)
void noBacklight(void); //turn off backlight
void IO_Expander_Write(unsigned char Data);
void LCD_Write_4Bit(unsigned char Nibble);
void LCD_CMD(unsigned char CMD);
void LCD_Write_Char(char);
void LCD_SR(void);
void LCD_SL(void);
void LCD_Clear(void);

// Function prototypes for hygro_pmod.c
float hygroi2c_getTemperature(); //captures a temperature reading from the Pmod HYGRO
float hygroi2c_getHumidity(); //captures a humidity reading from the Pmod HYGRO
void  hygroi2c_begin(); //initializes the Hygro I2C interface (must be done before every temp and humidity measurement)
uint8_t hygroi2c_writeRegI2C(uint8_t bReg, uint16_t bVal);
uint8_t hygroi2c_readRegI2C(uint8_t bReg, uint16_t *rVal, uint32_t delay_in_ms);
float hygroi2c_tempC2F(float tempC);
float hygroi2c_tempF2C(float tempF);


// Function prototypes for ultrasonic_sensor.c
int ultrasonic_sensor_cm(int trig_pin, int echo_pin); // returns distance in cm detected by the ultrasonic sensor


// Header file for prinf.c Sourced from: https://github.com/mpaland/printf
///////////////////////////////////////////////////////////////////////////////
// \author (c) Marco Paland (info@paland.com)
//             2014-2019, PALANDesign Hannover, Germany
//
// \license The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// \brief Tiny printf, sprintf and snprintf implementation, optimized for speed on
//        embedded systems with a very limited resources.
//        Use this instead of bloated standard/newlib printf.
//        These routines are thread safe and reentrant.
//
///////////////////////////////////////////////////////////////////////////////

#ifndef _PRINTF_H_
#define _PRINTF_H_

#include <stdarg.h>
#include <stddef.h>


#ifdef __cplusplus
extern "C" {
#endif


/**
 * Output a character to a custom device like UART, used by the printf() function
 * This function is declared here only. You have to write your custom implementation somewhere
 * \param character Character to output
 */
void _putchar(char character);


/**
 * Tiny printf implementation
 * You have to implement _putchar if you use printf()
 * To avoid conflicts with the regular printf() API it is overridden by macro defines
 * and internal underscore-appended functions like printf_() are used
 * \param format A string that specifies the format of the output
 * \return The number of characters that are written into the array, not counting the terminating null character
 */
#define printf printf_
int printf_(const char* format, ...);


/**
 * Tiny sprintf implementation
 * Due to security reasons (buffer overflow) YOU SHOULD CONSIDER USING (V)SNPRINTF INSTEAD!
 * \param buffer A pointer to the buffer where to store the formatted string. MUST be big enough to store the output!
 * \param format A string that specifies the format of the output
 * \return The number of characters that are WRITTEN into the buffer, not counting the terminating null character
 */
#define sprintf sprintf_
int sprintf_(char* buffer, const char* format, ...);


/**
 * Tiny snprintf/vsnprintf implementation
 * \param buffer A pointer to the buffer where to store the formatted string
 * \param count The maximum number of characters to store in the buffer, including a terminating null character
 * \param format A string that specifies the format of the output
 * \param va A value identifying a variable arguments list
 * \return The number of characters that COULD have been written into the buffer, not counting the terminating
 *         null character. A value equal or larger than count indicates truncation. Only when the returned value
 *         is non-negative and less than count, the string has been completely written.
 */
#define snprintf  snprintf_
#define vsnprintf vsnprintf_
int  snprintf_(char* buffer, size_t count, const char* format, ...);
int vsnprintf_(char* buffer, size_t count, const char* format, va_list va);


/**
 * Tiny vprintf implementation
 * \param format A string that specifies the format of the output
 * \param va A value identifying a variable arguments list
 * \return The number of characters that are WRITTEN into the buffer, not counting the terminating null character
 */
#define vprintf vprintf_
int vprintf_(const char* format, va_list va);


/**
 * printf with output function
 * You may use this as dynamic alternative to printf() with its fixed _putchar() output
 * \param out An output function which takes one character and an argument pointer
 * \param arg An argument pointer for user data passed to output function
 * \param format A string that specifies the format of the output
 * \return The number of characters that are sent to the output function, not counting the terminating null character
 */
int fctprintf(void (*out)(char character, void* arg), void* arg, const char* format, ...);


#ifdef __cplusplus
}
#endif


#endif  // _PRINTF_H_




