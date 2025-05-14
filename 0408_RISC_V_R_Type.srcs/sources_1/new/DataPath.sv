`timescale 1ns / 1ps

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl

);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;

    assign instrMemAddr = PCOutData;

    RegisterFile U_RegrFile (
        .clk   (clk),
        .we    (regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr (instrCode[11:7]),
        .WData (aluResult),
        .RData1(RFData1),
        .RData2(RFData2)
    );
    alu U_ALU (
        .aluControl(aluControl),
        .a         (RFData1),
        .b         (RFData2),
        .result    (aluResult)
    );
    register U_PC (
        .clk  (clk),
        .reset(reset),
        .d    (PCSrcData),
        .q    (PCOutData)
    );
    adder U_PC_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PCSrcData)

    );
endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            4'd0: result = a + b;
            4'd1: result = a - b;
            4'd2: result = a << b;
            4'd3: result = a >> b;
            4'd4: begin
                result = a >> b;
                if (a[31]) begin
                    result = result | 32'hffff_ffff << (32 - b);
                end
            end
            4'd5: begin
                case ({
                    a[31], b[31]
                })
                    2'b00:   result = a < b;
                    2'b01:   result = 0;
                    2'b10:   result = 1;
                    2'b11:   result = (~a + 1 > ~b + 1);
                    default: result = 32'bx;
                endcase
            end
            4'd6: result = (a < b) ? 1 : 0;
            4'd7: result = a ^ b;
            4'd8: result = a | b;
            4'd9: result = a & b;
        endcase
    end
endmodule

module register (
    input logic clk,
    input logic reset,
    input logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= 0;
        else q <= d;
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y

);
    assign y = a + b;
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RAddr1,
    input  logic [ 4:0] RAddr2,
    input  logic [ 4:0] WAddr,
    input  logic [31:0] WData,
    output logic [31:0] RData1,
    output logic [31:0] RData2
);
    logic [31:0] RegFile[0:2**5- 1];  //32비트 짜리의 공간이 32개
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 10 + i;
        end
        //  RegFile[1] = 32'h11111111;
        //  RegFile[2] = 32'h00000001;
    end


    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule


