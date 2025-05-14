`timescale 1ns / 1ps

module MCU(
    input logic clk,
    input logic reset
    );

    logic [31:0] instrCode;
    logic [31:0] instrMemAddr;

RV32I_Core U_Core (.*);

rom U_ROM (
    .addr(instrMemAddr),
    .data(instrCode)
);

endmodule
