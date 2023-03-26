#include <stdint.h> 
#include <rv32i.h>

volatile uint32_t *uart_tx_data = (volatile uint32_t *) UART_TX_DATA;
volatile uint32_t *uart_tx_busy = (volatile uint32_t *) UART_TX_BUSY;
volatile uint32_t *uart_rx_full = (volatile uint32_t *) UART_RX_BUFFER_FULL;
volatile uint32_t *uart_rx_data = (volatile uint32_t *) UART_RX_DATA;

// print characters serially via UART
void uart_print(char *message) {
    int i = 0;
    while (message[i] != '\0') {
        while (*uart_tx_busy);  // wait for UART to be ready
        *uart_tx_data = message[i];
        i++;
    }
}

//check if read buffer is full and data can be read
int uart_rx_buffer_full(){
    int ready = *uart_rx_full;
    return ready;
}

//read data from buffer (make sure to check first if rx buffer is full)
char uart_read(){
    char read_data;
    read_data = *uart_rx_data; 
    return read_data;
}







