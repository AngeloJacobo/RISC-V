#include <stdint.h> 
#include <rv32i.h>

volatile uint32_t *uart_tx_data = (volatile uint32_t *) UART_TX_DATA_ADDR;
volatile uint32_t *uart_tx_busy = (volatile uint32_t *) UART_TX_BUSY_ADDR;

// print characters serially via UART
void uart_print(char *message) {
    int i = 0;
    while (message[i] != '\0') {
        while (*uart_tx_busy);  // wait for UART to be ready
        *uart_tx_data = message[i];
        i++;
    }
}