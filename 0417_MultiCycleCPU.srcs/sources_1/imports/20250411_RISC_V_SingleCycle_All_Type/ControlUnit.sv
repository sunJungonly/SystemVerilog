`timescale 1ns / 1ps

`include "defines.sv"

module ControlUnit (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        aluSrcMuxSel,
    output logic        dataWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr,
    output logic        PCen
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operators = {
        instrCode[30], instrCode[14:12]
    };  // {func7[5], func3}

    logic [9:0] signals;
    assign {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;

    localparam FETCH = 0, DECODE = 1,
               TYPE_R = 2,
               TYPE_I = 3, 
               TYPE_L = 4, TYPE_L_WB = 5,  TYPE_L_MEM = 6,
               TYPE_S = 7, TYPE_S_MEM = 8,
               TYPE_B = 9,
               TYPE_LU = 10,
               TYPE_AU = 11,
               TYPE_J = 12,
               TYPE_JL = 13;
    logic [3:0] state, state_next;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) state <= FETCH;
        else state <= state_next;
    end

    always_comb begin
        state_next = state;
        PCen = 0;
        signals = 9'b0;
        case (state)
            FETCH: begin
                PCen = 1;
                state_next = DECODE;
            end
            DECODE: begin
                PCen = 0;
                case (opcode)
                    // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel(3), branch, jal, jalr} = signals
                    `OP_TYPE_R:  begin state_next = TYPE_R; 
                    signals = 9'b1_0_0_000_0_0_0; 
                    end
                    `OP_TYPE_S:  begin state_next = TYPE_S; 
                    signals = 9'b0_1_1_000_0_0_0; 
                    end
                    `OP_TYPE_L:  begin state_next = TYPE_L; 
                    signals = 9'b1_1_0_001_0_0_0; 
                    end
                    `OP_TYPE_I:  begin state_next = TYPE_I; 
                    signals = 9'b1_1_0_000_0_0_0; 
                    end
                    `OP_TYPE_B:  begin state_next = TYPE_B; 
                    signals = 9'b0_0_0_000_1_0_0; 
                    end
                    `OP_TYPE_LU: begin state_next = TYPE_LU; 
                    signals = 9'b1_0_0_010_0_0_0; 
                    end
                    `OP_TYPE_AU: begin state_next = TYPE_AU; 
                    signals = 9'b1_0_0_011_0_0_0; 
                    end
                    `OP_TYPE_J:  begin state_next = TYPE_J; 
                    signals = 9'b1_0_0_100_0_1_0;
                    end
                    `OP_TYPE_JL: begin state_next = TYPE_JL;
                    signals = 9'b1_0_0_100_0_1_1; 
                    end
                endcase
            end
            TYPE_R: begin
                PCen = 0;
                signals = 9'b1_0_0_000_0_0_0;
                state_next = FETCH;
            end
            TYPE_I: begin
                PCen = 0;
                signals = 9'b1_1_0_000_0_0_0;
                state_next = FETCH;
            end
            TYPE_L: begin
                PCen = 0;
                signals = 9'b1_1_0_001_0_0_0; 
                state_next = TYPE_L_MEM;
            end
            TYPE_L_WB: begin
                PCen = 0;
                signals = 9'b1_1_0_001_0_0_0; 
                state_next = FETCH;
            end
            TYPE_L_MEM: begin
                PCen = 0;
                signals = 9'b1_1_0_001_0_0_0; 
                state_next = TYPE_L_WB;
            end
            TYPE_S: begin
                PCen = 0;
                signals = 9'b0_1_1_000_0_0_0;
                state_next = TYPE_S_MEM;
            end
            TYPE_S_MEM: begin
                PCen = 0;
                signals = 9'b0_1_1_000_0_0_0;
                state_next = FETCH;
            end
            TYPE_B: begin
                PCen = 0;
                signals = 9'b0_0_0_000_1_0_0; 
                state_next = FETCH;
            end
            TYPE_LU: begin
                PCen = 0;
                signals = 9'b1_0_0_010_0_0_0; 
                state_next = FETCH;
            end
            TYPE_AU: begin
                PCen = 0;
                signals = 9'b1_0_0_011_0_0_0; 
                state_next = FETCH;
            end
            TYPE_J: begin
                PCen = 0;
                state_next = FETCH;
                signals = 9'b1_0_0_100_0_1_0;
            end
            TYPE_JL: begin
                PCen = 0;
                state_next = FETCH;
                signals = 9'b1_0_0_100_0_1_1;
            end
        endcase
    end

    // always_comb begin
    //     signals = 9'b0;
    //     case (opcode)
    //         // {regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel(3), branch, jal, jalr} = signals
    //         `OP_TYPE_R:  signals = 9'b1_0_0_000_0_0_0;
    //         `OP_TYPE_S:  signals = 9'b0_1_1_000_0_0_0;
    //         `OP_TYPE_L:  signals = 9'b1_1_0_001_0_0_0;
    //         `OP_TYPE_I:  signals = 9'b1_1_0_000_0_0_0;
    //         `OP_TYPE_B:  signals = 9'b0_0_0_000_1_0_0;
    //         `OP_TYPE_LU: signals = 9'b1_0_0_010_0_0_0;
    //         `OP_TYPE_AU: signals = 9'b1_0_0_011_0_0_0;
    //         `OP_TYPE_J:  signals = 9'b1_0_0_100_0_1_0;
    //         `OP_TYPE_JL: signals = 9'b1_0_0_100_0_1_1;
    //     endcase
    // end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            `OP_TYPE_S: aluControl = `ADD;
            `OP_TYPE_L: aluControl = `ADD;
            `OP_TYPE_JL: aluControl = `ADD;  // {func7[5], func3}
            `OP_TYPE_I: begin
                if (operators == 4'b1101)
                    aluControl = operators;  // {1'b1, func3}
                else aluControl = {1'b0, operators[2:0]};  // {1'b0, func3}
            end
            default: aluControl = operators;  // {func7[5], func3}
            // `OP_TYPE_R:  aluControl = operators;  // {func7[5], func3}
            // `OP_TYPE_B:  aluControl = operators;  // {func7[5], func3}
            // `OP_TYPE_LU: aluControl = operators;  // {func7[5], func3}
            // `OP_TYPE_AU: aluControl = operators;  // {func7[5], func3}
            // `OP_TYPE_J:  aluControl = operators;  // {func7[5], func3}
        endcase
    end
endmodule
