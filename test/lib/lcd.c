#include <stdint.h> 
#include <rv32i.h>
// Source: https://deepbluembedded.com/interfacing-i2c-lcd-16x2-tutorial-with-pic-microcontrollers-mplab-xc8/

unsigned char RS, i2c_add, BackLight_State = LCD_BACKLIGHT;
 
void LCD_Init() //initialize LCD with proper routine
{
  i2c_add = LCD_I2C_ADDR;
  IO_Expander_Write(0x00);
   delay_ms(30); 
  LCD_CMD(0x03);
   delay_ms(5);
  LCD_CMD(0x03);
   delay_ms(5);
  LCD_CMD(0x03);
   delay_ms(5);
  LCD_CMD(LCD_RETURN_HOME);
   delay_ms(5); 
  LCD_CMD(0x20 | (LCD_TYPE << 2));
   delay_ms(50);
  LCD_CMD(LCD_TURN_ON);
   delay_ms(50);
  LCD_CMD(LCD_CLEAR);
   delay_ms(50);
  LCD_CMD(LCD_ENTRY_MODE_SET | LCD_RETURN_HOME);
   delay_ms(50);
}
 
void IO_Expander_Write(unsigned char Data) 
{
  uint8_t addr_ack, data_ack;
  addr_ack = i2c_write_address(i2c_add<<1);
  data_ack = i2c_write_byte(Data | BackLight_State);
  i2c_stop();
}
 
void LCD_Write_4Bit(unsigned char Nibble)
{
  // Get The RS Value To LSB OF Data
  Nibble |= RS;
  IO_Expander_Write(Nibble | 0x04);
  IO_Expander_Write(Nibble & 0xFB);
   delay_ms(50);
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
 
void LCD_Write_String(char* Str) //write string to LCD
{
  for(int i=0; Str[i]!='\0'; i++)
    LCD_Write_Char(Str[i]);
}
 
void LCD_Set_Cursor(unsigned char ROW, unsigned char COL) //Set cursor where to start writing to LCD
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
 
void Backlight(void) //turn on backlight (initially turned on)
{
  BackLight_State = LCD_BACKLIGHT;
  IO_Expander_Write(0);
}
 
void noBacklight(void) //turn off backlight
{
  BackLight_State = LCD_NOBACKLIGHT;
  IO_Expander_Write(0);
}
 
void LCD_SL(void)
{
  LCD_CMD(0x18);
   delay_ms(40); 
}
 
void LCD_SR(void)
{
  LCD_CMD(0x1C);
   delay_ms(40); 
}
 
void LCD_Clear(void)
{
  LCD_CMD(0x01);
   delay_ms(40); 
}

