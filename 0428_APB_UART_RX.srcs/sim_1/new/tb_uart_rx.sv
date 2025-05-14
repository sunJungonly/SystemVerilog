`timescale 1ns / 1ps

module tb_uart_rx( );

 // 100 MHz clock -> 10 ns period
    logic PCLK = 0;
    always #5 PCLK = ~PCLK;

    logic PRESET;
    logic [3:0] PADDR;
    logic [31:0] PWDATA;
    logic PWRITE;
    logic PENABLE;
    logic PSEL;
    logic [31:0] PRDATA;
    logic PREADY;
    logic RX;

    // Instantiate the DUT
    Uart_RX_Periph dut (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .RX(RX)
    );

    // UART bit period for 9600 baud at 100 MHz clock
    localparam BAUD_TICKS = 16;
    localparam BIT_PERIOD = 104167; // ns (1/9600)

    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            RX = 0;
            #(BIT_PERIOD);

            // 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                RX = data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            RX = 1;
            #(BIT_PERIOD);
        end
    endtask

    // APB read helper task // APB는 동기식 프로토콜이기 때문에, 클럭 상승엣지 기준으로 동작
    task apb_read(input [3:0] addr);
        begin
            @(posedge PCLK);
            PADDR   = addr;
            PWRITE  = 0;
            PSEL    = 1;
            PENABLE = 1;
            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK); // 슬레이브가 준비될 때까지 대기 (즉, read 완료까지 기다림)
            PENABLE = 0;
            PSEL = 0;
            $display("Read from 0x%0h = 0x%0h", addr, PRDATA);
        end
    endtask

    initial begin
        // Initialize
        PRESET = 1;
        RX = 1; // idle
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;

        #100;
        PRESET = 0;

        #1000;

        // Send byte 0xA5 = 1010_0101
        uart_send_byte(8'hA5);

        // Wait enough time for receive to complete
        #2000000; // 2 ms

        // Send byte 0x5A = 0101_1010
        uart_send_byte(8'h5A); // 데이터2
        // Wait enough time for receive to complete
        #2000000; // 2 ms
        
        // Send byte 0x3C = 0011_1100
        uart_send_byte(8'h3C); // 데이터3
        // Wait enough time for receive to complete
        #2000000; // 2 ms

        // Send byte 0x3C = 1111_1111
        uart_send_byte(8'hFF); // 추가 데이터 (255 값 확인용)
        // Wait enough time for receive to complete
        #2000000; // 2 ms

        // Read RX FIFO Status (optional)
        apb_read(4'h0); // fsr

        apb_read(4'h4); // rx_data (frd)
        #1000;
        apb_read(4'h4); // rx_data (frd)

        #1000;
        $finish;
    end
endmodule
