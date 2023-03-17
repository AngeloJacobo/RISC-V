#include <stdint.h> //added -ffreestanding on gcc command to pass this

#define I2C_START 8100
#define I2C_WRITE 8104
#define I2C_READ 8108
#define I2C_BUSY 8112
#define I2C_ACK 8116
#define I2C_READ_DATA_READY 8120
#define I2C_STOP 8124

#define UART_TX_DATA_ADDR 8052
#define UART_TX_BUSY_ADDR 8056

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

/* File: I2C_LCD.h */
 
 
#define LCD_BACKLIGHT         0x08
#define LCD_NOBACKLIGHT       0x00
#define LCD_FIRST_ROW         0x80
#define LCD_SECOND_ROW        0xC0
#define LCD_THIRD_ROW         0x94
#define LCD_FOURTH_ROW        0xD4
#define LCD_CLEAR             0x01
#define LCD_RETURN_HOME       0x02
#define LCD_ENTRY_MODE_SET    0x04
#define LCD_CURSOR_OFF        0x0C
#define LCD_UNDERLINE_ON      0x0E
#define LCD_BLINK_CURSOR_ON   0x0F
#define LCD_MOVE_CURSOR_LEFT  0x10
#define LCD_MOVE_CURSOR_RIGHT 0x14
#define LCD_TURN_ON           0x0C
#define LCD_TURN_OFF          0x08
#define LCD_SHIFT_LEFT        0x18
#define LCD_SHIFT_RIGHT       0x1E
#define LCD_TYPE              2 // 0 -> 5x7 | 1 -> 5x10 | 2 -> 2 lines
 
//-----------[ Functions' Prototypes ]--------------
//---[ LCD Routines ]---
 
void LCD_Init(unsigned char I2C_Add);
void IO_Expander_Write(unsigned char Data);
void LCD_Write_4Bit(unsigned char Nibble);
void LCD_CMD(unsigned char CMD);
void LCD_Set_Cursor(unsigned char ROW, unsigned char COL);
void LCD_Write_Char(char);
void LCD_Write_String(char*);
void Backlight();
void noBacklight();
void LCD_SR();
void LCD_SL();
void LCD_Clear();

unsigned char RS, i2c_add, BackLight_State = LCD_BACKLIGHT;
 


//======================================================
 
//---------------[ LCD Routines ]----------------
//-----------------------------------------------
 
void LCD_Init(unsigned char I2C_Add)
{
  i2c_add = I2C_Add;
  IO_Expander_Write(0x00);
  wait_cycles(360000); //__delay_ms(30);
  LCD_CMD(0x03);
  wait_cycles(60000);//__delay_ms(5);
  LCD_CMD(0x03);
  wait_cycles(60000);//__delay_ms(5);
  LCD_CMD(0x03);
  wait_cycles(60000);//__delay_ms(5);
  LCD_CMD(LCD_RETURN_HOME);
  wait_cycles(60000); //__delay_ms(5);
  LCD_CMD(0x20 | (LCD_TYPE << 2));
  wait_cycles(600000);//__delay_ms(50);
  LCD_CMD(LCD_TURN_ON);
  wait_cycles(600000);//__delay_ms(50);
  LCD_CMD(LCD_CLEAR);
  wait_cycles(600000);//__delay_ms(50);
  LCD_CMD(LCD_ENTRY_MODE_SET | LCD_RETURN_HOME);
  wait_cycles(600000);//__delay_ms(50);
}
 
void IO_Expander_Write(unsigned char Data) //all good
{
  uint8_t addr_ack, data_ack;
  addr_ack = i2c_write_address(i2c_add);
  data_ack = i2c_write_byte(Data | BackLight_State);

  if(addr_ack) {
      uart_print("Address Acknowledged");
  }
  else {
      uart_print("Address NOT Acknowledged");
  }

  if(data_ack) {
      uart_print("Data Acknowledged");
  }
  else {
      uart_print("Data NOT Acknowledged");
  }
  i2c_stop();
}
 
void LCD_Write_4Bit(unsigned char Nibble)
{
  // Get The RS Value To LSB OF Data
  Nibble |= RS;
  IO_Expander_Write(Nibble | 0x04);
  IO_Expander_Write(Nibble & 0xFB);
  wait_cycles(600);//__delay_us(50);
}
 
void LCD_CMD(unsigned char CMD)
{
  RS = 0; // Command Register Select
  LCD_Write_4Bit(CMD & 0xF0);
  LCD_Write_4Bit((CMD << 4) & 0xF0);
}
 
void LCD_Write_Char(char Data)
{
  RS = 1; // Data Register Select
  LCD_Write_4Bit(Data & 0xF0);
  LCD_Write_4Bit((Data << 4) & 0xF0);
}
 
void LCD_Write_String(char* Str)
{
  for(int i=0; Str[i]!='\0'; i++)
    LCD_Write_Char(Str[i]);
}
 
void LCD_Set_Cursor(unsigned char ROW, unsigned char COL)
{
  switch(ROW)
  {
    case 2:
      LCD_CMD(0xC0 + COL-1);
      break;
    case 3:
      LCD_CMD(0x94 + COL-1);
      break;
    case 4:
      LCD_CMD(0xD4 + COL-1);
      break;
    // Case 1
    default:
      LCD_CMD(0x80 + COL-1);
  }
}
 
void Backlight()
{
  BackLight_State = LCD_BACKLIGHT;
  IO_Expander_Write(0);
}
 
void noBacklight()
{
  BackLight_State = LCD_NOBACKLIGHT;
  IO_Expander_Write(0);
}
 
void LCD_SL()
{
  LCD_CMD(0x18);
  wait_cycles(480); //__delay_us(40);
}
 
void LCD_SR()
{
  LCD_CMD(0x1C);
  wait_cycles(480); //__delay_us(40);
}
 
void LCD_Clear()
{
  LCD_CMD(0x01);
  wait_cycles(480); //__delay_us(40);
}

 

/*
* File: main.c
* Author: Khaled Magdy
*/
 
int main(void) {
 
  uart_print("INITIALIZING LCD MODULE.....\n");
  LCD_Init(0x4E); // Initialize LCD module with I2C address = 0x4E
  uart_print("INITIALIZING DONE!\n\n");
 
  LCD_Set_Cursor(1, 1);
  LCD_Write_String(" Angelo Jacobo");
  LCD_Set_Cursor(2, 1);
  LCD_Write_String("Team Gagraduates");
  while(1){
  }
 
  return 1;
}








