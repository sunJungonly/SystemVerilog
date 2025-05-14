`timescale 1ns / 1ps

module tb_fifo_status_reg ();
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

    FIFO_Status_Register dut (.*);

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

        
        // 2. FWD 레지스터에 데이터 쓰기 (직접 지정 값)
        // 첫 번째 값: 0xA1
        PSEL   = 1;
        PWRITE = 1;
        PADDR  = 4;  // FWD 레지스터(0x04)
        PWDATA = 32'h000000A1;
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);

        // 두 번째 값: 0xB2
        PSEL   = 1;
        PWRITE = 1;
        PADDR  = 4;
        PWDATA = 32'h000000B2;
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);

        // 세 번째 값: 0xC3
        PSEL   = 1;
        PWRITE = 1;
        PADDR  = 4;
        PWDATA = 32'h000000C3;
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);
        
        // 4. FRD 레지스터에서 데이터 읽기 (3번)
        // 첫 번째 읽기
        PSEL   = 1;
        PWRITE = 0;
        PADDR  = 8;  // FRD 레지스터(0x08)
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);
        repeat(1) @(posedge PCLK);

        // 두 번째 읽기
        PSEL   = 1;
        PWRITE = 0;
        PADDR  = 8;  // FRD 레지스터(0x08)
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);
        repeat(1) @(posedge PCLK);

        // 세 번째 읽기
        PSEL   = 1;
        PWRITE = 0;
        PADDR  = 8;  // FRD 레지스터(0x08)
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        @(posedge PCLK);
        
        // 5. FSR 최종 상태 확인
        PSEL   = 1;
        PWRITE = 0;
        PADDR  = 0;  // FSR 레지스터(0x00)
        @(posedge PCLK);
        PENABLE = 1;
        wait(PREADY);
        @(posedge PCLK);
        PSEL    = 0;
        PENABLE = 0;
        
        // 시뮬레이션 종료
        $finish;
    

end

endmodule
