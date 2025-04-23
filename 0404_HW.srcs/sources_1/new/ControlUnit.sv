`timescale 1ns / 1ps

module ControlUnit (
    input  logic clk,
    input  logic reset,
    output logic BSrcMuxsel,
    output logic BEn,
    input  logic BLt11,
    output logic ASrcMuxsel,
    output logic AEn,
    output logic OutBuf
);
    localparam S0 = 0, S1 = 1, S2 = 2, S3 = 3, S4 = 4, S5 = 5, S6 = 6;
    logic [2:0] state, state_next;

    always_ff @(posedge clk, posedge reset) begin : blockName
        if (reset) begin
            state <= S0;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        BSrcMuxsel = 0;
        BEn        = 0;
        AEn        = 0;
        ASrcMuxsel = 0;
        OutBuf     = 0;
        case (state)
            S0: begin
                BSrcMuxsel = 0; // MUX에서 x1(6'd1)을 선택
                BEn        = 0; // B 레지스터 활성화 (값 로드)
                ASrcMuxsel = 1; // MUX에서 x1(6'd0)을 선택
                AEn        = 1; // A 레지스터 활성화 (초기화)
                OutBuf     = 0; // 출력 비활성화
                state_next = S1;
            end
            S1: begin
                BSrcMuxsel = 1;
                BEn        = 1;
                ASrcMuxsel = 0;
                AEn        = 0;
                OutBuf     = 0;
                state_next = S2;
            end
            S2: begin
                BSrcMuxsel = 0;
                BEn        = 0;
                ASrcMuxsel = 0;
                AEn        = 0;
                OutBuf     = 0;
                if (BLt11) begin
                    state_next = S3;
                end else begin
                    state_next = S6;
                end
            end
            S3: begin
                BSrcMuxsel = 0;
                BEn        = 0;
                ASrcMuxsel = 0;
                AEn        = 0;
                OutBuf     = 1;
                state_next = S4;
            end
            S4: begin
                BSrcMuxsel = 1;
                BEn        = 0;
                ASrcMuxsel = 1;
                AEn        = 1;
                OutBuf     = 0;
                state_next = S5;
            end
            S5: begin
                BSrcMuxsel = 1;
                BEn        = 1;
                ASrcMuxsel = 0;
                AEn        = 0;
                OutBuf     = 0;
                state_next = S2;
            end
            S6: begin
                BSrcMuxsel = 0;
                BEn        = 0;
                ASrcMuxsel = 0;
                AEn        = 0;
                OutBuf     = 0;
                state_next = S6;
            end

        endcase

    end
endmodule
