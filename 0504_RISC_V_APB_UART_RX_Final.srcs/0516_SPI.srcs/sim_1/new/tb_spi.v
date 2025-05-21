`timescale 1ns / 1ps

module tb_spi();
    reg         clk;
    reg         rst;
    reg         btn;
    reg  [13:0] sw;
    //fnd port
    wire [ 3:0] com;
    wire [ 7:0] font;

    MCU_SPI dut(
    .clk(clk),
    .rst(rst),
    .btn(btn),
    .sw(sw),
    .com(com),
    .font(font)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; btn = 0; sw = 14'b0;
        #10 rst = 0;

        // Set switch value to transmit
        // #10 sw = 14'b0010_1010_1100_11;  // 임의의 //2739
        #10 sw = 14'b00_0100_1101_0010;  // 임의의 1234
                
        // "0021" 표시
        // #10 sw = 14'b0000_0000_1000_01; // D3=0, D2=0, D1=2, D0=1


        // Send button pulse to trigger SPI transmission
        #20 btn = 1;
        #10 btn = 0;

        // Wait and observe
        #30;

        // // Test 다른 값
        // sw = 14'b1111_0000_0000_00;
        // #20 btn = 1;
        // #10 btn = 0;

        #30;
        $finish;

    end
endmodule
