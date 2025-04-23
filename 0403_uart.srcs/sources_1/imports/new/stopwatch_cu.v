`timescale 1ns / 1ps
module stopwatch_cu(
    input clk,
    input reset,
    input i_btn_run,
    input i_btn_clear,
    input cl,
    output reg o_run,
    output reg o_clear
    );

    // fsm 구조로 CU 설계
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
    reg [1:0] state, next;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP; // STOP
        end else begin
            state <= next;
        end
    end

    // next
    always @(*) begin
        next = state;
            case (state)
                STOP: begin
                    if (cl) begin 
                        next = RUN;
                    end else begin
                    if (i_btn_run == 1) begin // 1'b1
                        next = RUN;
                    end else if (i_btn_clear == 1'b1) begin
                        next = CLEAR;
                    end // 맨 위에서 초기화 했기 때문에 else 필요 없음음
                    end
                end 
                RUN: begin
                    if (i_btn_run == 1) begin
                        next = STOP;
                    end
                end 
                CLEAR: begin
                    if (i_btn_clear == 1) begin
                        next = STOP;
                    end
                end 
            endcase
        end


//출력력
    always @(*) begin
        o_run = 1'b0;
        o_clear = 1'b0; // latch 방지
        case (state)    
            STOP: begin
                o_run = 1'b0;
                o_clear = 1'b0; // 1'b0
            end

            RUN: begin
                o_run = 1'b1;
                o_clear = 1'b0;
            end

            CLEAR: begin
                o_run = 1'b0;
                o_clear = 1'b1;
            end
        endcase
    end

endmodule
