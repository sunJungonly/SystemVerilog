`timescale 1ns / 1ps

module decimaltoASCII (
    input [3:0] data_digit,
    input clk,
    input reset,
    output [7:0] data_ASCII
);

    reg [7:0]data_reg, data_next;

    assign data_ASCII = data_reg;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            data_reg <= 0;
        end
        else begin
            data_reg <= data_next;
        end
    end

    always @(*) begin
        data_next = 8'h00;
        case (data_digit)
            4'h0: data_next = 8'h30;
            4'h1: data_next = 8'h31;
            4'h2: data_next = 8'h32;
            4'h3: data_next = 8'h33;
            4'h4: data_next = 8'h34;
            4'h5: data_next = 8'h35;
            4'h6: data_next = 8'h36;
            4'h7: data_next = 8'h37;
            4'h8: data_next = 8'h38;
            4'h9: data_next = 8'h39;
        endcase
    end
endmodule
