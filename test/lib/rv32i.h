// I2C memory-mapped registers
#define I2C_START 0x800000A0
#define I2C_WRITE 0x800000A4
#define I2C_READ 0x800000A8
#define I2C_BUSY 0x800000AC
#define I2C_ACK 0x800000B0
#define I2C_READ_DATA_READY 0x800000B4
#define I2C_STOP 0x800000B8

// UART memory-mapped registers
#define UART_TX_DATA_ADDR 0x80000050
#define UART_TX_BUSY_ADDR 0x80000054

// CLINT memory-mapped registers
#define CPU_CLK_HZ 12000000
#define MTIME_BASE_ADDRESS 0x80000000
#define MTIMECMP_BASE_ADDRESS 0x80000008
#define MSIP_BASE_ADDRESS 0x80000010

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

// Inline functions go to header file
static inline void __attribute__ ((always_inline)) csr_set(const int csr_id, uint32_t mask) { // set bits in CSR
  uint32_t csr_data = mask;
  asm volatile ("csrs %[input_i], %[input_j]" :  : [input_i] "i" (csr_id), [input_j] "r" (csr_data));
}
inline void __attribute__ ((always_inline)) csr_write(const int csr_id, uint32_t data) { // write to csr
  uint32_t csr_data = data;
  asm volatile ("csrw %[input_i], %[input_j]" :  : [input_i] "i" (csr_id), [input_j] "r" (csr_data));
}

// Function prototypes for i2c.c
uint8_t i2c_write_address(uint8_t addr); // start i2c by writing slave address (returns slave ack)
void i2c_stop(void); // stop current i2c transaction
uint8_t i2c_write_byte(uint8_t data); // write to slave (returns slave ack)

// Function prototypes for uart.c
void uart_print(char *message);

// Function prototypes for lcd.c
void LCD_Init(unsigned char I2C_Add); //initialize LCD with proper routine
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
