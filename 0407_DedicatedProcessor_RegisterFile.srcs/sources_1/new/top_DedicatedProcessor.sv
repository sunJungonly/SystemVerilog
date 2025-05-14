`timescale 1ns / 1ps

module top_DedicatedProcessor (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] outPort
);

    logic       RFSrcMuxSel;
    logic [2:0] readAddr1;
    logic [2:0] readAddr2;
    logic [2:0] writeAddr;
    logic       writeEn;
    logic       outBuf;
    logic       iLe10;

    DataPath U_DataPath (.*);
    ControlUnit U_ControlUnit (.*);

endmodule
