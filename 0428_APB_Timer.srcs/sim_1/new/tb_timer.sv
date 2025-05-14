`timescale 1ns / 1ps

module tb_timer();
    // global signal
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;

    Timer_Periph dut (.*);

    always #5 PCLK = ~PCLK;

    initial begin

    // 신호 초기화
    PCLK   = 0;
    PRESET = 1;
    PADDR  = 0;
    PWDATA = 0;
    PWRITE = 0;
    PENABLE = 0;
    PSEL   = 0;
    
    // 리셋 해제
    #10 PRESET = 0;
    end
endmodule
