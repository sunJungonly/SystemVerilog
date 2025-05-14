`timescale 1ns / 1ps

`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic        RFWDSrcMuxSel
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [3:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel} = signals;

    always_comb begin
        signals = 3'b0;
        case (opcode)
            // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel} = signals
            `OP_TYPE_R: signals = 4'b1_0_0_0;
            `OP_TYPE_S: signals = 4'b0_1_1_0;
            `OP_TYPE_L: signals = 4'b1_1_0_1;
            `OP_TYPE_I: signals = 4'b1_1_0_0;
            `OP_TYPE_B: signals = 4'b1_1_0_0;
        endcase
    end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            `OP_TYPE_R: aluControl = operators;  // {func7[5], func3}begin
            `OP_TYPE_S: aluControl = `ADD;
            `OP_TYPE_L: aluControl = `ADD;
            `OP_TYPE_I: begin
                if (operators == 4'b1101) aluControl = operators; // {f1'b1, func3}
                else aluControl = {1'b0, operators[2:0]}; // {f1'b0, func3}
            end
        endcase
    end
endmodule
