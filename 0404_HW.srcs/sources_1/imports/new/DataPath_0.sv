`timescale 1ns / 1ps

module DataPath_0 (
    input  logic       clk,
    input  logic       reset,
    input  logic       ASrcMuxsel,
    input  logic       AEn,
    output logic       ALt10,
    input  logic       OutBuf,
    output logic [7:0] outPort
);
    wire [7:0] y;
    wire [7:0] q;
    wire [7:0] sum;

    assign  outPort = OutBuf ? q : 8'hzz;
    
    mux U_Mux (
        .ASrcMuxsel(ASrcMuxsel),
        .x0(8'd0),
        .x1(sum),
        .y(y)
    );

    register U_Register (
        .clk(clk),
        .reset(reset),
        .en(AEn),
        .d(y),
        .q(q)
    );

    comparator U_Comparator (
        .a(q),
        .b(8'd10), //10
        .lt(ALt10)
    );

    adder U_Adder (
        .a(q),
        .b(8'd1),
        .sum(sum)
    );

    
endmodule

module register (
    input logic       clk,
    input logic       reset,
    input logic       en,
    input logic [7:0] d,
    output logic [7:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) begin
                q <= d;
            end
        end
    end
endmodule

module adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;
endmodule

module comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic lt
);
    assign lt = (a < b) ? 1 : 0;
endmodule

module mux (
    input logic ASrcMuxsel,
    input logic [7:0] x0,
    input logic [7:0] x1,
    output logic [7:0] y
);
    assign y = ASrcMuxsel ? x1 : x0;

endmodule
