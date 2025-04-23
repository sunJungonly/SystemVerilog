`timescale 1ns / 1ps

module DataPath (
    input  logic       clk,
    input  logic       reset,
    input  logic       BSrcMuxsel,
    input  logic       BEn,
    output logic       BLt11,
    input  logic       ASrcMuxsel,
    input  logic       AEn,
    input  logic       OutBuf,
    output logic [5:0] OutPort
);

    wire [5:0] a, b, a_q, b_q, sum, sum_b;

    assign OutPort = OutBuf ? sum : 8'hzz;

    mux_2x1 U_Mux_B (
        .SrcMuxsel(BSrcMuxsel),
        .x0(sum_b), //
        .x1(6'd1),
        .y(b)  //
    );

    register U_Register_B (
        .clk(clk),
        .reset(reset),
        .en(BEn),
        .d(b),  //
        .q(b_q) //
    );

    comparator U_Comparator_B (
        .x0(b_q),
        .x1(6'd11),
        .y (BLt11)
    );

    adder U_Adder_B (
        .a  (b_q), //
        .b  (6'd1),
        .sum(sum_b) //
    );

    mux_2x1 U_Mux_A (
        .SrcMuxsel(ASrcMuxsel),
        .x0(sum),
        .x1(6'd0),
        .y(a)
    );

    register U_Register_A (
        .clk(clk),
        .reset(reset),
        .en(AEn),
        .d(a),
        .q(a_q)
    );

    adder U_Adder_AB (
        .a  (a_q),
        .b  (b_q),
        .sum(sum)
    );

endmodule

module mux_2x1 (
    input  logic       SrcMuxsel,
    input  logic [5:0] x0,
    input  logic [5:0] x1, // 1
    output logic [5:0] y
);
    assign y = SrcMuxsel ? x0 : x1;
endmodule

module register (
    input  logic       clk,
    input  logic       reset,
    input  logic       en,
    input  logic [5:0] d,
    output logic [5:0] q
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

module comparator (
    input  logic [5:0] x0,
    input  logic [5:0] x1,
    output logic y
);
    assign y = (x0 < x1) ? 1 : 0;
endmodule

module adder (
    input  logic [5:0] a,
    input  logic [5:0] b,
    output logic [5:0] sum
);
    assign sum = a + b;
endmodule
