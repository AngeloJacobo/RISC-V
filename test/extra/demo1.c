#include <stdint.h>
#include <rv32i.h>
 
int main() {
  LCD_Init(); // Initialize LCD module with I2C address = 0x4E

  while(1){  
      LCD_Set_Cursor(1, 1); //set cursor to row 1 col 1
      LCD_Write_String("Demonstration #1");
      LCD_Set_Cursor(2, 1); //set cursor to row 2 col 1
      LCD_Write_String("Hello World!!!");
  }
  return 0;
}








