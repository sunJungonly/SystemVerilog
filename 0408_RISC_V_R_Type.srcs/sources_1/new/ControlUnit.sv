`timescale 1ns / 1ps

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {
        instrCode[30], instrCode[14:12]
    };  //{func7[5], func3}

    always_comb begin
        regFileWe = 1'b0;
        case (opcode)
            7'b0110011: regFileWe = 1'b1;  //R-Type
        endcase
    end

    always_comb begin
        aluControl = 4'bx;
        case (opcode)
            7'b0110011: begin  //R-Type
                aluControl = 4'bx;
                case (operator)
                    4'b0000: aluControl = 4'd0;  // add
                    4'b1000: aluControl = 4'd1;  // sub
                    4'b0001: aluControl = 4'd2;  // sll  
                    4'b0101: aluControl = 4'd3;  // srl
                    4'b1101: aluControl = 4'd4;  // sra
                    4'b0010: aluControl = 4'd5;  // slt
                    4'b0011: aluControl = 4'd6;  // sltu
                    4'b0100: aluControl = 4'd7;  // xor
                    4'b0110: aluControl = 4'd8;  // or
                    4'b0111: aluControl = 4'd9;  // and
                endcase
            end
        endcase
    end
endmodule
