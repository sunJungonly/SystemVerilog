`timescale 1ns / 1ps

module tb_top();

    logic clk;
    logic reset;

    top_Processor dut (
        .clk(clk),
        .reset(reset)
    );
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        #10
        reset = 0;
    end
endmodule
