`timescale 1ns / 1ps

module controlUnit(
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_done,
    input tx_done,
    input tx_busy,
    output reg tx_start,
    output [7:0] tx_data,
    output reg en,
    output reg clear,
    output reg mode
    );

    reg [7:0] tx_data_reg, tx_data_next;
    assign tx_data = tx_data_reg;
    reg[1:0] state, next;
    localparam STOP = 0, RUN = 1, UP = 2, CLEAR = 3; 

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            tx_data_reg <= 0;
        end else begin
            state <= next;
            tx_data_reg <= tx_data_next;
        end
    end

    always @(*) begin
        next = state;
        en = 1'b0;
        clear = 1'b0;
        tx_data_next = 0;
        case (state)
            STOP: begin
                tx_start = 0;
                en = 1'b0;
                clear = 1'b0;
                mode = 1'b1;
                if (rx_done == 1) begin
                    if (rx_data == 8'h72) begin
                        next = RUN;
                        if (tx_busy == 0) begin
                            tx_data_next = 8'h72;
                            tx_start = 1;
                        end
                    end else if (rx_data == 8'h63) begin
                        next = CLEAR;
                        if (tx_busy == 0) begin
                            tx_data_next = 8'h63;
                            tx_start = 1;
                        end
                    end
                end 
            end 
            RUN: begin
                tx_start = 0;
                en = 1'b1;
                clear = 1'b0;
                mode = 1'b1;
                if (rx_done) begin  
                    if (rx_data == 8'h73)  begin
                        next = STOP;
                        if (tx_busy == 0) begin
                            tx_data_next = 8'h73;
                            tx_start = 1;
                        end
                    end
                    else if (rx_data == 8'h6D) begin
                        next = UP;
                        if (tx_busy == 0) begin
                            tx_data_next = 8'h6D;
                            tx_start = 1;
                        end
                    end
                    else begin
                        next = RUN;
                    end
                end
            end

            UP: begin
                tx_start = 0;
                en = 1'b1;
                clear = 1'b0;
                mode = 1'b0;
                if (rx_done) begin
                    if (rx_data == 8'h6D) begin
                       next = RUN; 
                       if (tx_busy == 0) begin
                            tx_data_next = 8'h6D;
                            tx_start = 1;
                        end
                    end else if (rx_data == 8'h73) begin
                        next = STOP;
                        if (tx_busy == 0) begin
                            tx_data_next = 8'h73;
                            tx_start = 1;
                        end
                    end
                end
  
                
            end

            CLEAR: begin
                tx_start = 0;
                en = 1'b0;
                clear = 1'b1;
                mode = 1'b1;
                if (rx_data == 8'h73) begin
                    next = STOP;
                    if (tx_busy == 0) begin
                            tx_data_next = 8'h73;
                            tx_start = 1;
                        end
                end 
            end
        endcase
    end
endmodule
