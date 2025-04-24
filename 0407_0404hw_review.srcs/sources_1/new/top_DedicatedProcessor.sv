`timescale 1ns / 1ps

module top_DedicatedProcessor(
    input logic clk,
    input logic reset,
    output logic [7:0] outPort
    );

    logic sumSrcMuxSel;
    logic iSrcMuxSel;
    logic SumEn;
    logic iEn;
    logic adderSrcMuxSel;
    logic outBuf;
    logic iLe10;

    DataPath U_Data_Path (.*); //system verilog에서만 지원해주는 방식, 알아서 연결됨

    ControlUnit U_ControlUnit (.*);
endmodule
