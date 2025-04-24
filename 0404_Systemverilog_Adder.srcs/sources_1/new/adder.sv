`timescale 1ns / 1ps

module adder (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] sum,
    output       carry
);

    assign {carry, sum} = a + b;

endmodule
