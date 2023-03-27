#include <stdint.h>
#include <stdio.h>
#include <rv32i.h>

int main(){
    uart_print("Start HygroPMOD....\n");
    
  // Capture and print temperature and humidity data 2x per second
  int val;
  char msg[5]; //max of 5 chars
  
  while(1){
      hygroi2c_begin();
      val = (int) hygroi2c_getTemperature();
      itoa(val, msg, 10);
      uart_print("\nTemperature: ");
      uart_print(msg);
      
      val = (int) hygroi2c_getHumidity();   
      itoa(val, msg, 10);
      uart_print("\nHumidity: ");
      uart_print(msg);
      delay_ms(1000); // 1 sample per second (temp + humidity) maximum
  }
}
