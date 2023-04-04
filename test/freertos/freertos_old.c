// This is sourced from: https://github.com/stnolting/neorv32/blob/main/sw/example/demo_freeRTOS/main.c

/* Standard includes. */
#include <stdint.h>
#include "rv32i.h"

/* Kernel includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "semphr.h"


void vApplicationTickHook( void );
void vUartSend( void *pvParameters );
void vUARTReceive( void *pvParameters );
void vToggleGPIO( void *pvParameters );
void vLCD( void *pvParameters );
extern void freertos_risc_v_trap_handler( void );

char rx_data[2];
SemaphoreHandle_t uart_mutex;

int main( void )
{
    BaseType_t a;
    BaseType_t b;
    BaseType_t c;
    BaseType_t d;
    uart_print("FreeRTOS DEMO\n");
    csr_write(MTVEC, (uint32_t) &freertos_risc_v_trap_handler);
    uart_mutex = xSemaphoreCreateMutex();
    
	a = xTaskCreate( vUartSend,				            /* The function that implements the task. */
				"UART_SEND", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
				500, 		/* The size of the stack to allocate to the task. */
				NULL, 								/* The parameter passed to the task - not used in this case. */
				1, 	                                /* The priority assigned to the task. */
				NULL );								/* The task handle is not required, so NULL is passed. */
	
	if( a != pdPASS )
   {
        uart_print("First Task Failed to Create\n");
        return(1);
    }
    
    b = xTaskCreate( vLCD,				            /* The function that implements the task. */
		"LCD_WRITE", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
		500, 		/* The size of the stack to allocate to the task. */
		NULL, 								/* The parameter passed to the task - not used in this case. */
		1, 	                                /* The priority assigned to the task. */
		NULL );	
    
	if( b != pdPASS )
    {
        uart_print("Second Task Failed to Create\n");
        return(2);
    }
    
    c = xTaskCreate( vUARTReceive,				            /* The function that implements the task. */
		"LCD_WRITE", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
		500, 		/* The size of the stack to allocate to the task. */
		NULL, 								/* The parameter passed to the task - not used in this case. */
		1, 	                                /* The priority assigned to the task. */
		NULL );	
    
	if( c != pdPASS )
    {
        uart_print("Third Task Failed to Create\n");
        return(3);
    }
    
    d = xTaskCreate( vToggleGPIO,				            /* The function that implements the task. */
		"LCD_WRITE", 						/* The text name assigned to the task - for debug only as it is not used by the kernel. */
		500, 		/* The size of the stack to allocate to the task. */
		NULL, 								/* The parameter passed to the task - not used in this case. */
		1, 	                                /* The priority assigned to the task. */
		NULL );	
    
	if( d != pdPASS )
    {
        uart_print("Fourth Task Failed to Create\n");
        return(3);
    }

	/* Start the tasks and timer running. */
	vTaskStartScheduler();

	uart_print("ERROR: You reached past the vTaskStartScheduler()");

}

void vUartSend( void *pvParameters ){
    while(1){
        xSemaphoreTake(uart_mutex, portMAX_DELAY);
        uart_print("This is the 1st line and this is pretty long do you understand?\n");
        xSemaphoreGive(uart_mutex);
        vTaskDelay(1); //100 ticks
        xSemaphoreTake(uart_mutex, portMAX_DELAY);
        uart_print("This is the 2nd line and I guess I'm already out of words. Let's see if I can think of more things to say or am I stuck?\n");
        xSemaphoreGive(uart_mutex);
        vTaskDelay(1); //100 ticks
        xSemaphoreTake(uart_mutex, portMAX_DELAY);
        uart_print("This is the 3rd line and this is pretty long do you understand?\n");
        xSemaphoreGive(uart_mutex);
        vTaskDelay(1); //100 ticks
        xSemaphoreTake(uart_mutex, portMAX_DELAY);
        uart_print("This is the 4th line and I guess I'm already out of words. Let's see if I can think of more things to say or am I stuck?\n");
        xSemaphoreGive(uart_mutex);
        vTaskDelay(1); //100 ticks
    }
    
}

void vUARTReceive( void *pvParameters ){
    int buffer_full;
    rx_data[1] = '\0';
    while(1){
        buffer_full = uart_rx_buffer_full(); //check if read buffer is full and data can be read
        if(buffer_full){
            rx_data[0] = uart_read(); //read data from buffer (make sure to check first if rx buffer is full)
        }
        xSemaphoreTake(uart_mutex, portMAX_DELAY);
        uart_print("This is from vUARTReceive, is this still jumbled?\n");
        xSemaphoreGive(uart_mutex);
        vTaskDelay(1); //100 ticks
    }
}

void vToggleGPIO( void *pvParameters ){
    while(1){
        if(rx_data[0] == '0'){
            gpio_write_pin(8, 0); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(9, 0); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(10, 0); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(11, 0); //write to a specific GPIO pin (automatically set pin to write mode)
        }
        else if(rx_data[0] == '1') {
            gpio_write_pin(8, 1); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(9, 1); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(10, 1); //write to a specific GPIO pin (automatically set pin to write mode)
            gpio_write_pin(11, 1); //write to a specific GPIO pin (automatically set pin to write mode)
        }
    }
}

void vLCD( void *pvParameters ){
    int counter = 0;
    int length = 0;
    char string[16]; //max of 16 chars
    //uart_print("INITIALIZING LCD MODULE.....\n");
    LCD_Init(0x4E); // Initialize LCD module with I2C address = 0x4E
    //uart_print("INITIALIZING DONE!\n\n");

    LCD_Set_Cursor(1, 1);
    LCD_Write_String(" Angelo Jacobo");
    LCD_Set_Cursor(2, 3);
    //LCD_Clear();
    delay_ms(1000);
    while(1){
        //convert counter to string
        sprintf_(string, "%d", counter);
        //print to LCD
        LCD_Set_Cursor(2, 7);
        LCD_Write_String(string);
        delay_ms(1000); 
        //increment counter
        counter++;
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



















