`timescale 1ns / 1ps

module btn_debounce(
    input clk,
    input reset,
    input i_btn,
    output o_btn
    );

    reg [$clog2(100_000)-1:0] counter;
    reg r_1khz;

    reg [7:0] q_reg, q_next;
    reg edge_detect;
    

    always @(posedge clk , posedge reset) begin
        if (reset) begin
            counter <= 0;
            r_1khz <= 0; 
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                r_1khz <= 1;
            end else begin
                counter <= counter + 1;
                r_1khz <= 0;
            end
        end
    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;
        end
    end


    always @(i_btn, r_1khz) begin
        q_next = {i_btn, q_reg[7:1]};
    end

    assign btn_debounce = &q_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_detect <= 0;
        end else begin
            edge_detect <= btn_debounce;
        end
    end

    assign o_btn = btn_debounce & (~edge_detect);
    
endmodule
