#include <stdint.h>

#define __IO        volatile

typedef struct {
    __IO uint32_t MODER;
    __IO uint32_t ODR;
} GPIO_TypeDef;

typedef struct {
    __IO uint32_t FCR;
    __IO uint32_t FDR;
    __IO uint32_t FPR;
} FND_TypeDef;

typedef struct {
    __IO uint32_t FSR;
    __IO uint32_t FRD;
} UART_RX_TypeDef;

#define APB_BASEADDR     0x10000000
#define FNDE_BASEADDR    (APB_BASEADDR + 0x5000)
#define UART_RX_BASEADDR (APB_BASEADDR + 0x7000)

#define FNDE            ((FND_TypeDef *) FNDE_BASEADDR)
#define UART_RX         ((UART_RX_TypeDef *) UART_RX_BASEADDR)

#define UART_RX_EMPTY   (UART_RX->FSR & 0x01)
#define UART_RX_FULL    ((UART_RX->FSR >> 1) & 0x01)

#define FND_IN          1

void FND_init(FND_TypeDef * FND, uint32_t ON_OFF);
void FND_writeData(FND_TypeDef * FND, uint32_t ctrl, uint32_t data);

int main()
{
    // FND 초기화
    FND_init(FNDE, 1);
    FND_writeData(FNDE, 0, 48);
    uint32_t rx_char;

    // 메인 루프
    while(1){    
        if (!UART_RX_EMPTY && !UART_RX_FULL) {
            rx_char = UART_RX->FRD;
            FND_writeData(FNDE, 0, rx_char);
        }
    }
}
void FND_init(FND_TypeDef * FND, uint32_t ON_OFF){
    FND->FCR = ON_OFF; 
}

void FND_writeData(FND_TypeDef * FND, uint32_t ctrl, uint32_t data){
    FND->FPR = ctrl;
    FND->FDR = data;
}