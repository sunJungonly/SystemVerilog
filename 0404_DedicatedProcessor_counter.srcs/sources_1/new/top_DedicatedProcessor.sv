`timescale 1ns / 1ps

module top_DedicatedProcessor (
    input  logic clk,
    input  logic reset
);
    wire ASrcMuxsel, AEn, ALt10, OutBuf;
    ControlUnit U_CU (
        .clk(clk),
        .reset(reset),
        .ASrcMuxsel(ASrcMuxsel),
        .AEn(AEn),
        .ALt10(ALt10),
        .OutBuf(OutBuf)
    );

    DataPath_0 U_DP (
        .clk(clk),
        .reset(reset),
        .ASrcMuxsel(ASrcMuxsel),
        .AEn(AEn),
        .ALt10(ALt10),
        .OutBuf(OutBuf),
        .outPort(outPort)
    );
endmodule