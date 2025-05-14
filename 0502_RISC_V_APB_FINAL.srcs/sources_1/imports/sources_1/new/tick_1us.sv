`timescale 1ns / 1ps

module tick_1us #(
    parameter TICK_COUNT = 100,
    BIT_WIDTH = 7
) (
    input  logic clk,
    input  logic reset,
    output logic o_tick
);

    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_tick = tick_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next  = 1'b0;
        if (count_reg == TICK_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end
endmodule
