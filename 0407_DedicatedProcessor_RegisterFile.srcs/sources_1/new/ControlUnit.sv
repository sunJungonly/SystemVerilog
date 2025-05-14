`timescale 1ns / 1ps

module ControlUnit (
    input  logic       clk,
    input  logic       reset,
    output logic       RFSrcMuxSel,
    output logic [2:0] readAddr1,
    output logic [2:0] readAddr2,
    output logic [2:0] writeAddr,
    output logic       writeEn,
    output logic       outBuf,
    input  logic       iLe10
);
    typedef enum {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7
    } state_e;

    state_e state, state_next;
    logic [11:0] out_signals;

    assign {RFSrcMuxSel, readAddr1, readAddr2, writeAddr, writeEn, outBuf} = out_signals;
    //assign으로 묶어서 간단하게 표현현

    always_ff @(posedge clk, posedge reset) begin : state_reg
        if (reset) begin 
            state <= S0;
        end
        else begin
            state <= state_next;
        end
    end

    always_comb begin : state_next_machine
        state_next  = state;
        out_signals = 0;
        case (state)
            //{RFSrcMuxSel, readAddr1, readAddr2, writeAddr, writeEn, outBuf} = out_signals;
            //cpu의 머신 코드와 굉장히 유사
            S0: begin // R1 = 0
                out_signals = 12'b0_000_000_001_1_0;
                state_next     = S1;
            end
            S1: begin // R2 = 0
                out_signals = 12'b0_000_000_010_1_0;
                state_next     = S2;
            end
            S2: begin // R3 = 1;
                out_signals = 12'b1_000_000_011_1_0;
                state_next     = S3;
            end
            S3: begin // i <= 10
                out_signals = 12'b0_001_000_000_0_0;
                if (iLe10) state_next = S4;
                else state_next = S7;
            end
            S4: begin // R2 = R2 + R1
                out_signals = 12'b0_010_001_010_1_0;
                state_next     = S5;
            end
            S5: begin // R1 = R1 + R3(1)
                out_signals = 12'b0_001_011_001_1_0;
                state_next     = S6;
            end
            S6: begin // outport = R2
                out_signals = 12'b0_010_000_000_0_1;
                state_next     = S3;
            end
            S7: begin
                out_signals = 12'b0_000_000_000_0_0;
                state_next     = S7;
            end
        endcase
    end
endmodule
