`timescale 1ns / 1ps
  
module MCU (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] GPOA,
    input  logic [7:0] GPIB,
    inout  logic [7:0] GPIOC,
    inout  logic [7:0] GPIOD,
    output logic [3:0] fnd_Comm,
    output logic [7:0] fnd_Font,
    output logic       tx,
    input  logic       rx,
    inout  logic       dht_io,
    input  logic       echo,
    output logic       trig,
    output logic [6:0] d_state
);  
    // global signal
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL_RAM;
    logic        PSEL_GPO;
    logic        PSEL_GPI;
    logic        PSEL_GPIOC;
    logic        PSEL_GPIOD;
    logic        PSEL_FND;
    logic        PSEL_TIM;
    logic        PSEL_UART_RX;
    logic        PSEL_UART_TX;
    logic        PSEL_SRHC04;
    logic        PSEL_DHT11;
    logic [31:0] PRDATA_RAM;
    logic [31:0] PRDATA_GPO;
    logic [31:0] PRDATA_GPI;
    logic [31:0] PRDATA_GPIOC;
    logic [31:0] PRDATA_GPIOD;
    logic [31:0] PRDATA_FND;
    logic [31:0] PRDATA_TIM;
    logic [31:0] PRDATA_UART_RX;
    logic [31:0] PRDATA_UART_TX;
    logic [31:0] PRDATA_SRHC04;
    logic [31:0] PRDATA_DHT11;
    logic        PREADY_RAM;
    logic        PREADY_GPO;
    logic        PREADY_GPI;
    logic        PREADY_GPIOC;
    logic        PREADY_GPIOD;
    logic        PREADY_FND;
    logic        PREADY_TIM;
    logic        PREADY_UART_RX;
    logic        PREADY_UART_TX;
    logic        PREADY_SRHC04;
    logic        PREADY_DHT11;

    // CPU - APB Master Signals
    // Internal Interface Signals
    logic        transfer;  // trigger signal
    logic        ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic        write;
    logic        dataWe;
    logic [31:0] dataAddr;
    logic [31:0] dataWData;
    logic [31:0] dataRData;

    // ROM signals
    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

    logic        sw_start;
    logic        sw_mode;

    assign PCLK   = clk;
    assign PRESET = reset;
    assign addr   = dataAddr;
    assign wdata  = dataWData;
    assign rdata  = dataRData;
    assign write  = dataWe;

    rom U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    RV32I_Core U_Core (.*);

    APB_Master U_APB_Master (
        .*,
        .PSEL0   (PSEL_RAM),
        .PSEL1   (PSEL_GPO),
        .PSEL2   (PSEL_GPI),
        .PSEL3   (PSEL_GPIOC),
        .PSEL4   (PSEL_GPIOD),
        .PSEL5   (PSEL_FND),
        .PSEL6   (PSEL_TIM),
        .PSEL7   (PSEL_UART_RX),
        .PSEL8   (PSEL_UART_TX),
        .PSEL9   (PSEL_SRHC04),
        .PSEL10  (PSEL_DHT11),
        .PRDATA0 (PRDATA_RAM),
        .PRDATA1 (PRDATA_GPO),
        .PRDATA2 (PRDATA_GPI),
        .PRDATA3 (PRDATA_GPIOC),
        .PRDATA4 (PRDATA_GPIOD),
        .PRDATA5 (PRDATA_FND),
        .PRDATA6 (PRDATA_TIM),
        .PRDATA7 (PRDATA_UART_RX),
        .PRDATA8 (PRDATA_UART_TX),
        .PRDATA9 (PRDATA_SRHC04),
        .PRDATA10(PRDATA_DHT11),
        .PREADY0 (PREADY_RAM),
        .PREADY1 (PREADY_GPO),
        .PREADY2 (PREADY_GPI),
        .PREADY3 (PREADY_GPIOC),
        .PREADY4 (PREADY_GPIOD),
        .PREADY5 (PREADY_FND),
        .PREADY6 (PREADY_TIM),
        .PREADY7 (PREADY_UART_RX),
        .PREADY8 (PREADY_UART_TX),
        .PREADY9 (PREADY_SRHC04),
        .PREADY10(PREADY_DHT11)
    );

    ram U_RAM (
        .*,
        .PSEL  (PSEL_RAM),
        .PRDATA(PRDATA_RAM),
        .PREADY(PREADY_RAM)
    );

    GPO_Periph U_GPOA (
        .*,
        .PSEL(PSEL_GPO),
        .PRDATA(PRDATA_GPO),
        .PREADY(PREADY_GPO),
        .outPort(GPOA)
    );

    GPI_Periph U_GPIB (
        .*,
        .PSEL  (PSEL_GPI),
        .PRDATA(PRDATA_GPI),
        .PREADY(PREADY_GPI),
        .inPort(GPIB)
    );

    GPIO_Periph U_GPIOC (
        .*,
        .PSEL   (PSEL_GPIOC),
        .PRDATA(PRDATA_GPIOC),
        .PREADY(PREADY_GPIOC),
        .inoutPort(GPIOC)
    );

    GPIO_Periph U_GPIOD (
        .*,
        .PSEL     (PSEL_GPIOD),
        .PRDATA   (PRDATA_GPIOD),
        .PREADY   (PREADY_GPIOD),
        .inoutPort(GPIOD)
    );

    FND_Periph U_FND_Periph (
        .*,
        .PSEL    (PSEL_FND),
        .PRDATA  (PRDATA_FND),
        .PREADY  (PREADY_FND),
        .fnd_Comm(fnd_Comm),
        .fnd_Font(fnd_Font)
    );

    timer_peri U_Timer_peri (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL_TIM),
        .PRDATA (PRDATA_TIM),
        .PREADY (PREADY_TIM)
    );

    Uart_RX_Periph U_UART_RX_Periph (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL_UART_RX),
        .PRDATA (PRDATA_UART_RX),
        .PREADY (PREADY_UART_RX),
        .RX     (rx)
    );
    UART_TX_Periph U_UART_TX_Periph (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL_UART_TX),
        .PRDATA (PRDATA_UART_TX),
        .PREADY (PREADY_UART_TX),
        .tx     (tx)
    );

    Ultrasonic_Periph U_SRHC04 (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL_SRHC04),
        .PRDATA (PRDATA_SRHC04),
        .PREADY (PREADY_SRHC04),
        .echo   (echo),
        .trig   (trig),
        .d_state(d_state)
    );

    dht11_peri U_DHT11 (
        .PCLK   (PCLK),
        .PRESET (PRESET),
        .PADDR  (PADDR),
        .PWDATA (PWDATA),
        .PWRITE (PWRITE),
        .PENABLE(PENABLE),
        .PSEL   (PSEL_DHT11),
        .PRDATA (PRDATA_DHT11),
        .PREADY (PREADY_DHT11),
        .dht_io (dht_io)
    );

endmodule
