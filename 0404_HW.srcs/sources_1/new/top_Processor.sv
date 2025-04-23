`timescale 1ns / 1ps

module top_Processor(
    input  logic clk,
    input  logic reset
);
    wire BSrcMuxsel, BEn, BLt11, ASrcMuxsel, AEn, OutBuf;
    ControlUnit U_CU (
        .clk(clk),
        .reset(reset),
        .BSrcMuxsel(BSrcMuxsel),
        .BEn(BEn),
        .BLt11(BLt11),
        .ASrcMuxsel(ASrcMuxsel),
        .AEn(AEn),
        .OutBuf(OutBuf)
    );

    DataPath U_DP (
        .clk(clk),
        .reset(reset),
        .BSrcMuxsel(BSrcMuxsel),
        .BEn(BEn),
        .BLt11(BLt11),
        .ASrcMuxsel(ASrcMuxsel),
        .AEn(AEn),
        .OutBuf(OutBuf),
        .OutPort(OutPort)
    );

endmodule
