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
    // export signals
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
    // output logic [1:0] sel_2bit
);
  
    logic        fcr;
    logic [ 13:0] fdr;
    logic [  3:0] fpr;

    APB_SlaveIntf_FndController U_APB_Intf_FndController (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .fcr(fcr),
        .fdr(fdr),
        .fpr(fpr)
    );
    FndController U_FndController (
        .clk(PCLK),
        .reset(PRESET),
        .fcr(fcr),
        .fdr(fdr),
        .fpr(fpr),
        .fndCom(fndCom),
        .fndFont(fndFont)  
    );
endmodule

module APB_SlaveIntf_FndController (
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
    // internal signals
    output logic        fcr,
    output logic [ 13:0] fdr,
    output logic [  3:0] fpr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  // slv_reg3;

    assign fcr = slv_reg0[0];
    assign fdr = slv_reg1[13:0];
    assign fpr = slv_reg2[ 3:0];

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
    
module FndController (
    input  logic       clk,
    input  logic       reset,
    input  logic       fcr,
    input  logic [13:0] fdr,
    input  logic [ 3:0] fpr,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
    // output logic [1:0] sel_2bit
);
   
    wire tick;
    wire [1:0] digit_sel;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;
    wire [3:0] w_fndCom;
    wire [7:0] fndSegData;
    wire fndDp;

    // assign sel_2bit = digit_sel;
    assign fndFont = {fndDp, fndSegData[6:0]};
    assign fndCom = (fcr)? w_fndCom: 4'b1111;

    // ASCIItoSEG_decoder U_ASCIItoSEG (  // 새 디코더 사용
    //     .ascii(ascii),
    //     .seg(seg_ascii)
    // );

    clk_div_1khz U_Clk_Div_1Khz (
        .clk  (clk),
        .reset(reset),
        .tick (tick)
    );

    counter_2bit U_Counter_2bit (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .count(digit_sel)
    );

    decoder_2x4 U_Dec_2x4 (
        .x(digit_sel),
        .y(w_fndCom)
    );



    digitSplitter U_Digit_Splitter (
        .fndData(fdr),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );

    mux_4x1 U_Mux_4x1 (
        .sel(digit_sel),
        .x0 (digit_1),
        .x1 (digit_10),
        .x2 (digit_100),
        .x3 (digit_1000),
        .y  (digit)
    );

    BCDtoSEG_decoder U_BCDtoSEG (
        .bcd(digit),
        .seg(seg_bcd)
    );

    mux_4x1_1bit U_Mux_4x1_1bit (
        .sel(digit_sel),
        .x  (fpr),
        .y  (fndDp)
    );


endmodule



module mux_4x1_1bit (
    input      [1:0] sel,
    input      [3:0] x,
    output reg       y
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


module clk_div_1khz ( 
    input clk,
    input reset,
    output reg tick
);
    reg [$clog2(100_000)-1 : 0] div_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if (div_counter == 100_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module counter_2bit (
    input            clk,
    input            reset,
    input            tick,
    output reg [1:0] count
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input      [1:0] x,
    output reg [3:0] y
);
    
always_comb begin
        y = 4'b1111;
        case (x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
    end
endmodule

module digitSplitter (
    input  [13:0] fndData,
    output [ 3:0] digit_1,
    output [ 3:0] digit_10,
    output [ 3:0] digit_100,
    output [ 3:0] digit_1000
);
    assign digit_1    = fndData % 10;
    assign digit_10   = fndData / 10 % 10;
    assign digit_100  = fndData / 100 % 10;
    assign digit_1000 = fndData / 1000 % 10;
endmodule

module mux_4x1 (
    input      [1:0] sel,
    input      [3:0] x0,
    input      [3:0] x1,
    input      [3:0] x2,
    input      [3:0] x3,
    output reg [3:0] y
);
    
always_comb begin
        y = 4'b0000;
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end
endmodule
  
module BCDtoSEG_decoder (
    input      [3:0] bcd,
    output reg [7:0] seg
);    
    
always_comb begin
        case (bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hf9;
            4'h2: seg = 8'ha4;
            4'h3: seg = 8'hb0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'ha: seg = 8'h88;
            4'hb: seg = 8'h83;
            4'hc: seg = 8'hc6;
            4'hd: seg = 8'ha1;
            4'he: seg = 8'h86;
            4'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule

// module ASCIItoSEG_decoder (  
//     input [7:0] ascii,
//     output reg [7:0] seg
// );

// always_comb begin
//         case(ascii)
            
//             // 알파벳 대문자 
//             8'h53: seg = 8'h92; // 'S'
//             8'h54: seg = 8'h87; // 'T'
//             default: seg = 8'hFF;
//         endcase
//     end
// endmodule