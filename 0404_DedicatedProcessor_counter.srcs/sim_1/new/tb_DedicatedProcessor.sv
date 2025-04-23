`timescale 1ns / 1ps

module tb_DedicatedProcessor();

    reg clk;
    reg reset;

top_DedicatedProcessor dut (
    .clk(clk),
    .reset(reset)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    reset = 1;
    #10;
    reset = 0;
end
endmodule
