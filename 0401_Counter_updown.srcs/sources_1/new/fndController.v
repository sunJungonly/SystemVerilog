`timescale 1ns / 1ps

module fndController(
    input clk,
    input rst,
    input [13:0] fndData,
    output [3:0] fndCom,
    output [7:0] fndFont
    
    );

    wire tick;
    wire [1:0] digit_sel;
    wire [3:0] digit_1, digit_10, digit_100, digit_1000, digit;
    wire [3:0] digit_10_dot;

    clk_div_1khz U_Clk_Div_1Khz(
        .clk(clk),
        .rst(rst),
        .tick(tick)
    );

    counter_2bit U_Counter_2Bit(
        .clk(clk),
        .rst(rst),
        .tick(tick),
        .count(digit_sel)
    );
    decoder_2x4 U_Decoder(
        .x(digit_sel),
        .y(fndCom)
    );
    digitSplitter U_DigitSplitter(
        .fndData(fndData),
        .digit_1(digit_1),
        .digit_10(digit_10),
        .digit_100(digit_100),
        .digit_1000(digit_1000)
    );

    dot U_dot (
    .clk(clk),
    .rst(rst),
    .digit_sel(digit_sel), 
    .digit_1(digit_1),
    .seg7(fndFont[7])
    );
    mux_4x1 U_Mux_4x1 (
        .sel(digit_sel),
        .x0(digit_1),
        .x1(digit_10),
        .x2(digit_100),
        .x3(digit_1000),
        .y(digit)
    );
    BCDtoSEG U_BCDtoSEG(
        .bcd(digit),
        .seg(fndFont[6:0])
    );
endmodule

module clk_div_1khz (
    input clk,
    input rst,
    output reg tick
);
    
    reg [$clog2(100_000) - 1 : 0] div_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            div_counter <= 0;
            tick <= 1'b0;
        end
        else begin
            if(div_counter == 100_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end
            else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule

module counter_2bit (
    input clk,
    input rst,
    input tick,
    output reg [1:0] count
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count <= 0;
        end
        else begin
            if (tick) begin    
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input [1:0] x,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b1111; //경우의 수가 다 있을 땐 필수 아님님
        case (x)
            2'b00: y = 4'b1110; 
            2'b01: y = 4'b1101; 
            2'b10: y = 4'b1011; 
            2'b11: y = 4'b0111;  
        endcase
    end
endmodule

module digitSplitter (
    input [13:0] fndData,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1 = fndData % 10;
    assign digit_10 = fndData / 10 % 10;
    assign digit_100 = fndData / 100 % 10;
    assign digit_1000 = fndData / 1000 % 10;
endmodule

module dot (
    input clk,
    input rst,
    input [1:0] digit_sel, 
    input [3:0] digit_1,
    output reg seg7
);

    always @(*) begin
        if (digit_sel == 2'b01) begin
            if (digit_1 < 5) begin
                seg7 = 1'b1; //꺼짐
            end else begin
                seg7 = 1'b0;
            end
        end else begin
            seg7 = 1'b1;
        end
    end


endmodule

module mux_4x1 (
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b0000;
        case (sel)
            2'b00: y= x0; 
            2'b01: y= x1; 
            2'b10: y= x2; 
            2'b11: y= x3;  
        endcase
    end
endmodule

module BCDtoSEG(
    input [3:0] bcd,
    output reg [6:0] seg
);

    always@(bcd) begin 
            case(bcd) 
                4'h0: seg=8'hc0;
                4'h1: seg=8'hf9;
                4'h2: seg=8'ha4;
                4'h3: seg=8'hb0; 
                4'h4: seg=8'h99;
                4'h5: seg=8'h92;
                4'h6: seg=8'h82;
                4'h7: seg=8'hf8;
                4'h8: seg=8'h80;
                4'h9: seg=8'h90;
                4'ha: seg=8'h88;
                4'hb: seg=8'h83;
                4'hc: seg=8'hc6;
                4'hd: seg=8'ha1; 
                4'he: seg=8'h86;
                4'hf: seg=8'h8e;
                default: seg = 8'hff;
            endcase

        end
    
endmodule

// module BCDtoSEG(
//     input [3:0] bcd,
//     output reg [7:0] seg
// );

//     always@(bcd) begin 
//             case(bcd) 
//                 4'h0: seg=8'b01000000;
//                 4'h1: seg=8'b01111001;
//                 4'h2: seg=8'b00100100;
//                 4'h3: seg=8'b00110000; 
//                 4'h4: seg=8'b00011001;
//                 4'h5: seg=8'b10010010;
//                 4'h6: seg=8'b10000010;
//                 4'h7: seg=8'b11111000;
//                 4'h8: seg=8'b10000000;
//                 4'h9: seg=8'b10010000;
//                 4'ha: seg=8'b10001000;
//                 4'hb: seg=8'b10000011;
//                 4'hc: seg=8'b11000110;
//                 4'hd: seg=8'b10100001; 
//                 4'he: seg=8'b10000110;
//                 4'hf: seg=8'b10001110;
//                 default: seg = 8'hff;
//             endcase

//         end
    
// endmodule