`timescale 1ns / 1ps

module FND_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    output logic [ 3:0] fnd_Comm,
    output logic [ 7:0] fnd_Font
);
    logic        fcr;
    logic [15:0] fdr;
    logic [ 3:0] fpr;
    logic        w_tick;
    logic [ 1:0] w_count4;
    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_digit_out;
    logic [7:0] fnd_in;

    clk_divider U_clk_divider (
        .*,
        .o_tick(w_tick)
    );

    count_4 U_count_4 (
        .*,
        .tick(w_tick),
        .count_4(w_count4)
    );

    decoder2X4 U_decoder2X4 (
        .fcr(fcr),
        .decode_in (w_count4),
        .decode_out(fnd_Comm)
    );

    digitsplitter U_digitsplitter (
        .data_in(fdr),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux4X1 U_mux4X1 (
        .sel(w_count4),
        .digit_1000(w_digit_1000),
        .digit_100(w_digit_100),
        .digit_10(w_digit_10),
        .digit_1(w_digit_1),
        .fnd_Font(w_digit_out)
    );

    APB_SlaveIntf_FND U_APB_SlaveIntf_FND (.*);

    FND U_FND (
        .fdr(w_digit_out),
        .fnd_Font(fnd_in)
    );

    dot_print U_dot_print(
        .sel(w_count4),
        .fpr(fpr),
        .fnd_in(fnd_in),
        .fnd_out(fnd_Font)
    );

endmodule

module APB_SlaveIntf_FND (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    output logic        fcr,
    output logic [15:0] fdr,
    output logic [ 3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //slv_reg3;

    assign fcr = slv_reg0[0];
    assign fdr = slv_reg1[15:0];
    assign fpr = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;  // FND control register(0x00)
                        2'd1: slv_reg1 <= PWDATA;  // FND Data register(0x04)
                        2'd2: slv_reg2 <= PWDATA;  // FND DP register(0x08)
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule

module FND (
    input logic [3:0] fdr,
    output logic [7:0] fnd_Font
);
    always_comb begin
        case (fdr)
            4'h0: fnd_Font = 8'hC0;
            4'h1: fnd_Font = 8'hf9;
            4'h2: fnd_Font = 8'ha4;
            4'h3: fnd_Font = 8'hb0;
            4'h4: fnd_Font = 8'h99;
            4'h5: fnd_Font = 8'h92;
            4'h6: fnd_Font = 8'h82;
            4'h7: fnd_Font = 8'hf8;
            4'h8: fnd_Font = 8'h80;
            4'h9: fnd_Font = 8'h90;
            4'hA: fnd_Font = 8'h88;
            4'hB: fnd_Font = 8'h83;
            4'hC: fnd_Font = 8'hC6;
            4'hD: fnd_Font = 8'hA1;
            4'hE: fnd_Font = 8'h86;
            4'hF: fnd_Font = 8'h8E;
            default: fnd_Font = 8'hC0;
        endcase
    end
endmodule

module clk_divider (
    input  logic PCLK,
    input  logic PRESET,
    output logic o_tick
);
    parameter FCOUNT = 500_000;
    logic [$clog2(FCOUNT)-1:0] count_reg;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            count_reg <= 0;
            o_tick <= 0;
        end else begin
            if (count_reg == FCOUNT) begin
                count_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                count_reg <= count_reg + 1;
                o_tick <= 1'b0;
            end
        end
    end
endmodule

module count_4 (
    input logic PCLK,
    input logic PRESET,
    input logic tick,
    output logic [1:0] count_4
);

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            count_4 <= 0;
        end else begin
            if (tick) begin
                count_4 <= count_4 + 1;
            end
        end
    end
endmodule

module decoder2X4 (
    input logic fcr,
    input  logic [1:0] decode_in,
    output logic [3:0] decode_out
);
    always_comb begin
        if(fcr) begin
            case (decode_in)
                2'b00:   decode_out = 4'b1110;
                2'b01:   decode_out = 4'b1101;
                2'b10:   decode_out = 4'b1011;
                2'b11:   decode_out = 4'b0111;
                default: decode_out = 4'b1111;
            endcase
        end
        else begin
            decode_out = 4'b1111;
        end
    end
endmodule

module digitsplitter (
    input  logic [15:0] data_in,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);
    assign digit_1 = data_in % 10;
    assign digit_10 = data_in / 10 % 10;
    assign digit_100 = data_in / 100 % 10;
    assign digit_1000 = data_in / 1000 % 10;
endmodule

module mux4X1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1000,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_1,
    output logic [3:0] fnd_Font
);
    always_comb begin
        case (sel)
            2'b00:   fnd_Font = digit_1;
            2'b01:   fnd_Font = digit_10;
            2'b10:   fnd_Font = digit_100;
            2'b11:   fnd_Font = digit_1000;
            default: fnd_Font = 4'h0;
        endcase
    end
endmodule

module dot_print (
    input logic [1:0] sel,
    input logic [3:0] fpr,
    input logic [7:0] fnd_in,
    output logic [7:0] fnd_out
);
    always_comb begin
        case (sel)
            2'b00: fnd_out = {~fpr[0], fnd_in[6:0]}; 
            2'b01: fnd_out = {~fpr[1], fnd_in[6:0]}; 
            2'b10: fnd_out = {~fpr[2], fnd_in[6:0]}; 
            2'b11: fnd_out = {~fpr[3], fnd_in[6:0]}; 
            default: fnd_out = fnd_in;
        endcase
    end
endmodule