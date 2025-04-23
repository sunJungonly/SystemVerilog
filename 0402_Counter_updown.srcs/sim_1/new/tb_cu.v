`timescale 1ns / 1ps

module tb_cu(    );

    reg clk;
    reg reset;
    reg [7:0] rx_data;
    reg rx_done;
    wire en;
    wire clear;
    wire mode;

controlUnit dut (
    .clk(clk),
    .reset(reset),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .en(en),
    .clear(clear),
    .mode(mode)
    );

always #5 clk = ~clk;

initial begin
    // 초기화
    clk = 0;
    reset = 1;
    #10;
    reset = 0;
    #10;

    rx_done = 1;
    #100;
    rx_data = 8'h72;
    #100;
    rx_data = 8'h6D;
    #100;
    rx_data = 8'h6D;
    #100;
end
    

endmodule
