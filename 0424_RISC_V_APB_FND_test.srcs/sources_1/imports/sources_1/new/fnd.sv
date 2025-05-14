`timescale 1ns / 1ps

module FndController_Periph (
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
    // outport signals
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont
);  
    logic fcr;
    // logic [3:0] fmr;
    logic [13:0] fdr;
    logic [3:0] fpr;

    APB_SlaveIntf_FND U_APB_Intf (.*);
    fndcontroller U_FndController (
        .clk(PCLK),
        .reset(PRESET),
        .*
    );

endmodule

module APB_SlaveIntf_FND (
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
    // internal signals
    output logic  fcr,
    // output logic [ 7:0] fmr,
    output logic [13:0] fdr, 
    output logic [3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1; 
    logic [31:0] slv_reg2;
    //logic [31:0] slv_reg3;

    assign fcr = slv_reg0[0];
    //assign fmr = slv_reg1[3:0];
    assign fdr = slv_reg1[13:0];
    assign fpr = slv_reg2[3:0];

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0; //fcr
            slv_reg1 <= 0; //fdr
            slv_reg2 <= 0; //fpr
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: slv_reg1 <= PWDATA;
                        2'd2: slv_reg2 <= PWDATA;
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
  

module fndcontroller (
    input  logic        clk,
    input  logic        reset,
    input  logic        fcr,
    //input  logic [3:0] fmr,
    input  logic [13:0] fdr,
    input  logic [ 3:0] fpr,
    output logic [ 3:0] fndCom,
    output logic [ 7:0] fndFont
);  
              
    logic [3:0] digit_1, digit_10, digit_100, digit_1000;
    logic o_clk;
    logic [1:0] o_sel;
    logic [3:0] bcd;
    logic [3:0] w_fndCom;
    logic [7:0] w_fndFont;
    logic fndDp;

    assign fndCom = fcr ? w_fndCom : 4'b1111;
    assign fndFont = {fndDp, w_fndFont[6:0]};

    always_comb begin  
        case (bcd)
            4'h0: w_fndFont = 8'hc0;
            4'h1: w_fndFont = 8'hf9;
            4'h2: w_fndFont = 8'ha4;
            4'h3: w_fndFont = 8'hb0;
            4'h4: w_fndFont = 8'h99;
            4'h5: w_fndFont = 8'h92;
            4'h6: w_fndFont = 8'h82;
            4'h7: w_fndFont = 8'hf8;
            4'h8: w_fndFont = 8'h80;
            4'h9: w_fndFont = 8'h90;
            4'ha: w_fndFont = 8'h88;
            4'hb: w_fndFont = 8'h83;
            4'hc: w_fndFont = 8'hc6;
            4'hd: w_fndFont = 8'ha1;
            4'he: w_fndFont = 8'h86;
            4'hf: w_fndFont = 8'h8e;
            default: w_fndFont = 8'hff;
        endcase
    end
 
    clk_divider U_CLK_Div (
        .clk  (clk),
        .reset(reset),
        .o_clk(o_clk)
    );

    counter_4 U_Counter (

        .clk  (o_clk),
        .reset(reset),
        .o_sel(o_sel)
    );

    digit_splitter U_digit_splitter (
        .bcd(fdr),
        .*
    );

    mux_4X1 U_Mux_4x1 (
        .sel(o_sel),
        .*,
        .bcd(bcd)
    );

    decoder_2to4 U_Decoder (
        .x(o_sel),
        .fndCom(w_fndCom)
    );

    mux_4x1_1bit U_Mux_4x1_1bit (
        .sel(o_sel),
        .x(fpr),
        .y(fndDp)
    );
endmodule

module mux_4x1_1bit (
    input  logic [1:0] sel,
    input  logic [3:0] x,
    output logic  y 
);

    always_comb begin
        y = 1'b1;
        case (sel)
            2'b00: y = ~x[0]; 
            2'b01: y = ~x[1]; 
            2'b10: y = ~x[2]; 
            2'b11: y = ~x[3]; 
        endcase
    end
    
endmodule

module decoder_2to4 (
    input  logic [1:0] x,
    output logic [3:0] fndCom
);

    always_comb begin
        case (x)
            2'b00:   fndCom = 4'b1110;
            2'b01:   fndCom = 4'b1101;
            2'b10:   fndCom = 4'b1011;
            2'b11:   fndCom = 4'b0111;
            default: fndCom = 4'b1111;
        endcase
    end
endmodule

module digit_splitter (
    input  logic [13:0] bcd,
    output logic [ 3:0] digit_1,
    output logic [ 3:0] digit_10,
    output logic [ 3:0] digit_100,
    output logic [ 3:0] digit_1000
);
    // 1의자리 ~ 1000의 자리
    assign digit_1 = bcd % 10;
    assign digit_10 = bcd / 10 % 10;
    assign digit_100 = bcd / 100 % 10;
    assign digit_1000 = bcd / 1000 % 10;

endmodule


module mux_4X1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    output logic [3:0] bcd
);

    // always 안에서는 assign x
    // always 안에서 출력은 reg type
    always_comb begin
        case (sel)
            2'b00:   bcd = digit_1;
            2'b01:   bcd = digit_10;
            2'b10:   bcd = digit_100;
            2'b11:   bcd = digit_1000;
            default: bcd = 4'bx;
        endcase

    end
endmodule

module clk_divider (
    input  logic clk,
    input  logic reset,
    output logic o_clk
);
    parameter FCOUNT = 500_000;
    reg [$clog2(
FCOUNT
)-1:0] r_counter;  //$clog2 숫자를 나타내는데 필요한 비트수 계산
    reg r_clk;
    assign o_clk = r_clk;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;  //리셋 상태
            r_clk <= 1'b0;
        end else begin
            if (r_counter == FCOUNT - 1) begin  //clock divide 계산 
                r_counter <= 0;
                r_clk <= 1'b1;  //r_clk : 0->1
            end else begin
                r_counter <= r_counter + 1;
                r_clk <= 1'b0;  //r_clk: 0으로 유지
            end

        end
    end

endmodule


module counter_4 (
    input  logic clk,
    input  logic reset,
    output logic  [1:0] o_sel
);

    reg [1:0] r_counter;
    assign o_sel = r_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end

    end
endmodule
