#include <stdint.h> //add -ffreestanding on gcc command if there is error

#define UART_TX_DATA_ADDR 8052
#define UART_TX_BUSY_ADDR 8056

volatile uint32_t *uart_tx_data = (volatile uint32_t *) UART_TX_DATA_ADDR;
volatile uint32_t *uart_tx_busy = (volatile uint32_t *) UART_TX_BUSY_ADDR;

int main() {
    char* message = "MY MESSAGE\n\n";
    int i = 0;
    while (message[i] != '\0') {
        while (*uart_tx_busy);  // wait for UART to be ready
        *uart_tx_data = message[i];
        i++;
    }
    return 0;
}

