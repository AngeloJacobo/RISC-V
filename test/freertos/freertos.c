// This is sourced from: https://github.com/stnolting/neorv32/blob/main/sw/example/demo_freeRTOS/main.c

/* Standard includes. */
#include <stdint.h>
#include "rv32i.h"

/* Kernel includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"

// CONFIGURABLES 
int moisture_sensor_pin = 0; //gpio pin for moisture sensor
int motor_pump_pin = 1; //gpio pin fot water pump motor
int trig_pin = 2; //trigger pin for ultrasonic sensor
int echo_pin = 3; //echo pin for ultrasonic sensor 
int buzzer_pin = 4; //buzzer pin 
char buzzer_on_code[2] = "a"; //code for buzzer on
char buzzer_off_code[2] = "b"; //code for buzzer off
char water_pump_on_code[2] = "c"; //code for turning on water pump

// Tasks function prototypes
void vBluetoothReceive( void *pvParameters );
void vBluetoothSend( void *pvParameters );
void vHygroTempSensor( void *pvParameters );
void vMoistureSensor( void *pvParameters );
void vWaterPumpMotor( void *pvParameters );
void vUltraSonicSensor( void *pvParameters );
void vBuzzerOn( void *pvParameters );
void vBuzzerOff( void *pvParameters );
void vRTC( void *pvParameters );
void vLCD( void *pvParameters );

// Freertos functions
extern void freertos_risc_v_trap_handler( void );
void vApplicationTickHook( void );

// Global variables shared by tasks
char rx_data; //stores data received from bluetooth
int humidity, temperature; //stores humidity and temperature values
int buzzer_on; //turns on-off the buzzer
int moist; //stores if moist detected
int ultrasonic_distance_cm; //stores distance in cm detected by ultrasonic sensor
SemaphoreHandle_t i2c_mutex; //mutex for accessing I2C peripheral


// main function
int main( void )
{
    BaseType_t vBluetoothReceive_task,
                vBluetoothSend_task,
                vHygroTempSensor_task,
                vMoistureSensor_task,
                vWaterPumpMotor_task,
                vUltraSonicSensor_task,
                vBuzzerOn_task,
                vBuzzerOff_task,
                vLCD_task;
                
    csr_write(MTVEC, (uint32_t) &freertos_risc_v_trap_handler); // set the trap handler to FreeRTOS
    i2c_mutex = xSemaphoreCreateMutex(); //create semaphoe for accessing I2C peripheral
    
    // Create tasks
    vBluetoothReceive_task = 
        xTaskCreate( vBluetoothReceive,		/* The function that implements the task. */
        "vBluetoothReceive", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        100, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    
     vBluetoothSend_task = 
        xTaskCreate( vBluetoothSend,		/* The function that implements the task. */
        "vBluetoothSend", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        300, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    
    vHygroTempSensor_task = 
        xTaskCreate( vHygroTempSensor,		/* The function that implements the task. */
        "vHygroTempSensor", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        300, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	

    vMoistureSensor_task = 
        xTaskCreate( vMoistureSensor,		/* The function that implements the task. */
        "vMoistureSensor", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        300, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    
    vWaterPumpMotor_task = 
        xTaskCreate( vWaterPumpMotor,		/* The function that implements the task. */
        "vWaterPumpMotor", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        200, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	

    vUltraSonicSensor_task = 
        xTaskCreate( vUltraSonicSensor,		/* The function that implements the task. */
        "vUltraSonicSensor", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        300, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    
    vBuzzerOn_task = 
        xTaskCreate( vBuzzerOn,		/* The function that implements the task. */
        "vBuzzerOn", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        200, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	

    vBuzzerOff_task = 
        xTaskCreate( vBuzzerOff,		/* The function that implements the task. */
        "vBuzzerOff", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        200, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    
    vLCD_task = 
        xTaskCreate( vLCD,		/* The function that implements the task. */
        "vLCD", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
        300, 		                        /* The size of the stack to allocate to the task. */
        NULL, 								/* The parameter passed to the task - not used in this case. */
        1, 	                                /* The priority assigned to the task. */
        NULL );	
    

    // Check if all task creation passed
   
   	if( vBluetoothReceive_task != pdPASS )
    {
        uart_print("vBluetoothReceive Task Failed to Create\n");
        return(1);
    }
   
   	if( vBluetoothSend_task != pdPASS )
    {
        uart_print("vBluetoothSend Task Failed to Create\n");
        return(1);
    }
   
   	if( vHygroTempSensor_task != pdPASS )
    {
        uart_print("vHygroTempSensor Task Failed to Create\n");
        return(1);
    }
   
   	if( vMoistureSensor_task != pdPASS )
    {
        uart_print("vMoistureSensor Task Failed to Create\n");
        return(1);
    }
    
   	if( vWaterPumpMotor_task != pdPASS )
    {
        uart_print("vWaterPumpMotor Task Failed to Create\n");
        return(1);
    }
   
   	if( vUltraSonicSensor_task != pdPASS )
    {
        uart_print("vUltraSonicSensor Task Failed to Create\n");
        return(1);
    }
    
   	if( vBuzzerOn_task != pdPASS )
    {
        uart_print("vBuzzerOn Task Failed to Create\n");
        return(1);
    }
    
   	if( vBuzzerOff_task != pdPASS )
    {
        uart_print("vBuzzerOff Task Failed to Create\n");
        return(1);
    }
   
   	if( vLCD_task != pdPASS )
    {
        uart_print("vLCD Task Failed to Create\n");
        return(1);
    }
   
	/* Start the tasks and timer running. */
	vTaskStartScheduler();

	uart_print("ERROR: You reached past the vTaskStartScheduler()");

}

void vBluetoothReceive( void *pvParameters ){
    int buffer_full;
    while(1){
        buffer_full = uart_rx_buffer_full(); //check if read buffer is full and data can be read
        if(buffer_full){
            rx_data = uart_read(); //read data from buffer (make sure to check first if rx buffer is full)
        }
    }
}

void vBluetoothSend( void *pvParameters ){
    char msg[10];
    while(1){
        sprintf_(msg, "%d", temperature); //convert temperatue value in integer to char array
        uart_print(msg);  //print serially to bluetooth
        uart_print(";"); //delimiter
        sprintf_(msg, "%d", humidity); //convert humidity value in integer to char array
        uart_print(msg); //print serially to bluetooth
        uart_print(";"); //delimiter
        
        if(buzzer_on){ 
            uart_print(buzzer_on_code); //code for buzzer on
            uart_print(";"); //delimiter
        }
        else {
            uart_print(buzzer_off_code); //code for buzzer off
            uart_print(";"); //delimiter
        }
        uart_print("\n");
        delay_ms(500);
    }
}

void vHygroTempSensor( void *pvParameters ){
    while(1){ 
      xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
      hygroi2c_begin(); //restart hygroi2c sensor
      xSemaphoreGive(i2c_mutex); //release the mutex
      delay_ms(1); //add delay between taking semaphores
      
      xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
      temperature = (int)hygroi2c_getTemperature(); //retrieve temperature value
      xSemaphoreGive(i2c_mutex); //release the mutex
      delay_ms(1);
      
      xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantim
      humidity = (int)hygroi2c_getHumidity(); //retrieve humidity value
      xSemaphoreGive(i2c_mutex);
      delay_ms(1);
    }
}

void vMoistureSensor( void *pvParameters ){
    while(1){
        moist = !gpio_read_pin(moisture_sensor_pin); //moisture sensor is active low (0 when moist detected)
        delay_ms(1);
    }
}

void vWaterPumpMotor( void *pvParameters ){
   
    gpio_write_pin(motor_pump_pin, 1);
    while(1){
        if(!moist) {
           gpio_write_pin(motor_pump_pin, 0);
        }
        else{
           gpio_write_pin(motor_pump_pin, 1);
        }
        if(rx_data == water_pump_on_code[0]) {
            rx_data = 0;
            gpio_write_pin(motor_pump_pin, 0);
            delay_ms(3000);
            gpio_write_pin(motor_pump_pin, 1);
        }
        delay_ms(1);
    }
}

void vUltraSonicSensor( void *pvParameters ){
    while(1){
    ultrasonic_distance_cm = ultrasonic_sensor_cm(trig_pin, echo_pin); // returns distance in cm detected by the ultrasonic sensor
    delay_ms(1);
    }
}

void vBuzzerOff( void *pvParameters ){ 
    while(1){
        if(rx_data == buzzer_off_code[0]){
            gpio_write_pin(buzzer_pin, 0); //turn off buzzer using serial line
            rx_data = 0;
            buzzer_on = 0;
            gpio_write_pin(8, 0); //buzzer will turn on when distance detected is less than 10cm
        }
        delay_ms(1);
    }
} 

void vBuzzerOn( void *pvParameters ){
    gpio_write_pin(buzzer_pin, 0); //buzzer off
    buzzer_on = 0;
    delay_ms(5000);
    while(1){  
        if(ultrasonic_distance_cm < 10){ 
            gpio_write_pin(buzzer_pin, 1); //buzzer will turn on when distance detected is less than 10cm
            buzzer_on = 1; 
            delay_ms(10000); //buzzer remain on for 10 sec
        }
        else{
            gpio_write_pin(buzzer_pin, 0); //else turn buzzer off
            buzzer_on = 0;
        }
        delay_ms(1);
    }
}

void vLCD( void *pvParameters ){
    char msg[10];
    xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
    LCD_Init(); // Initialize LCD module
    LCD_Set_Cursor(1, 1);
    LCD_Write_String("RISC-V with RTOS");
    LCD_Set_Cursor(2, 1);
    LCD_Write_String("Team GraduatECEs");
    delay_ms(1000);
    LCD_Clear();
    xSemaphoreGive(i2c_mutex); //release the mutex
    while(1){
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Set_Cursor(1, 1);
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
 
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String("Temp:");
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
                
        sprintf_(msg, "%d", temperature); //convert humidity value in integer to char array
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String(msg);
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
                
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String("C ");
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
        
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String("Hum:");
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
        
        sprintf_(msg, "%d", humidity); //convert humidity value in integer to char array
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String(msg);
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
        
        xSemaphoreTake(i2c_mutex, portMAX_DELAY); //gain access to the i2c peripheral and not let other task to use it for the meantime
        LCD_Write_String("%");
        xSemaphoreGive(i2c_mutex); //release the mutex
        delay_ms(1); 
    }
}


/* This handler is responsible for handling all interrupts. Only the machine timer interrupt is handled by the kernel. */
void SystemIrqHandler( uint32_t mcause )
{
  uart_print("freeRTOS: Unknown interrupt \n");
}

void vApplicationTickHook( void ){
}




void vApplicationMallocFailedHook( void )
{
	/* vApplicationMallocFailedHook() will only be called if
	configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
	function that will get called if a call to pvPortMalloc() fails.
	pvPortMalloc() is called internally by the kernel whenever a task, queue,
	timer or semaphore is created.  It is also called by various parts of the
	demo application.  If heap_1.c or heap_2.c are used, then the size of the
	heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
	FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
	to query the size of free heap space that remains (although it does not
	provide information on how the remaining heap might be fragmented). */
	taskDISABLE_INTERRUPTS();
    uart_print("FreeRTOS_FAULT: vApplicationMallocFailedHook (solution: increase 'configTOTAL_HEAP_SIZE' in FreeRTOSConfig.h)\n");
    __asm volatile( "nop" );
	__asm volatile( "ebreak" );
	for( ;; );
}
/*-----------------------------------------------------------*/

void vApplicationIdleHook( void )
{
	/* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
	to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
	task.  It is essential that code added to this hook function never attempts
	to block in any way (for example, call xQueueReceive() with a block time
	specified, or call vTaskDelay()).  If the application makes use of the
	vTaskDelete() API function (as this demo application does) then it is also
	important that vApplicationIdleHook() is permitted to return to its calling
	function, because it is the responsibility of the idle task to clean up
	memory allocated by the kernel to any task that has since been deleted. */
}

/*-----------------------------------------------------------*/

void vApplicationStackOverflowHook( TaskHandle_t pxTask, char *pcTaskName )
{
	( void ) pcTaskName;
	( void ) pxTask;

	/* Run time stack overflow checking is performed if
	configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
	function is called if a stack overflow is detected. */
	taskDISABLE_INTERRUPTS();
    uart_print("FreeRTOS_FAULT: vApplicationStackOverflowHook\n");
    __asm volatile( "nop" );
    __asm volatile( "nop" );
	__asm volatile( "ebreak" );
	for( ;; );
}



















