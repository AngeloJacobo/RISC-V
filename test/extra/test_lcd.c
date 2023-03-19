#include <stdint.h>
#include <rv32i.h>
 
int main(void) {
 
  uart_print("INITIALIZING LCD MODULE.....\n");
  LCD_Init(0x4E); // Initialize LCD module with I2C address = 0x4E
  uart_print("INITIALIZING DONE!\n\n");
 
  LCD_Set_Cursor(1, 1);
  LCD_Write_String(" Angelo Jacobo");
  LCD_Set_Cursor(2, 1);
  LCD_Write_String("BSECE-4A");
  //while(1){
  //}
 
  return 1;
}








