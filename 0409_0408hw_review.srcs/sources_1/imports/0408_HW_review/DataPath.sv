`timescale 1ns / 1ps

`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    //control unit side port
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    input  logic        RFWDSrcMuxSel,
    //instr memory side port
    output logic [31:0] instrMemAddr,
    input  logic [31:0] instrCode,
    // data memory side port
    input  logic [31:0] dataRData,
    output logic [31:0] dataAddr,
    output logic [31:0] dataWData
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] immExt, aluSrcMuxOut, RFWDSrcMuxOut, memLData, memWData;

    assign instrMemAddr = PCOutData;
    assign dataAddr     = aluResult;
    assign dataWData    = memWData;


    RegisterFile U_RegFile (
        .clk(clk),
        .we(regFileWe),
        .RAddr1(instrCode[19:15]),
        .RAddr2(instrCode[24:20]),
        .WAddr(instrCode[11:7]),
        .WData(memLData),
        .RData1(RFData1),
        .RData2(RFData2)
    );

    mux_2X1 U_ALUSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    mux_2X1 U_RFWDSrcMux(
        .sel(RFWDSrcMuxSel),
        .x0(aluResult),
        .x1(dataRData),
        .y(RFWDSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a(RFData1),
        .b(aluSrcMuxOut),
        .result(aluResult)
    );

    extend U_ImmExtend (
        .instrCode(instrCode),
        .immExt(immExt)
    );

    register U_PC (
        .clk(clk),
        .reset(reset),
        .d(PCSrcData),
        .q(PCOutData)
    );

    adder U_PC_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PCSrcData)
    );

    byte_half U_S_Data_Byte_Half (
        .instrCode(instrCode),
        .dataWData(RFData2),
        .memWData(memWData)
    );

    byte_half U_L_Data_Byte_Half (
        .instrCode(instrCode),
        .dataWData(RFWDSrcMuxOut),
        .memWData(memLData)
    );
endmodule


module byte_half (
    input  logic [31:0] instrCode,
    input logic [31:0] dataWData,
    output logic [31:0] memWData
);
    always_comb begin        
        if(instrCode[14:12] == 3'b000 | instrCode[14:12] == 3'b001 | instrCode[14:12] == 3'b010)
            memWData =
            (instrCode[14:12] == 3'b000) ? {{24{dataWData[7]}}, dataWData[7:0]} :
            (instrCode[14:12] == 3'b001) ? {{16{dataWData[15]}}, dataWData[15:0]} : dataWData;
        else 
            memWData =
            (instrCode[14:12] == 3'b100) ? {{24'd0}, dataWData[7:0]} :
            (instrCode[14:12] == 3'b101) ? {{16'd0}, dataWData[15:0]} : dataWData;
    end
endmodule
//  case (instrCode[14:12])
//         // Byte (8비트)
//         3'b000: memWData = (instrCode[6:0] == 7'b0000011) ? {{24{dataWData[7]}}, dataWData[7:0]} : {{24'd0}, dataWData[7:0]};
        
//         // Halfword (16비트)
//         3'b001: memWData = (instrCode[6:0] == 7'b0000011) ? {{16{dataWData[15]}}, dataWData[15:0]} : {{16'd0}, dataWData[15:0]};
        
//         // Word (32비트)
//         3'b010: memWData = dataWData;

//         // 기본값
//         default: memWData = 32'd0;
//     endcase
// end

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);
    always_comb begin
        case (aluControl)
            `ADD: result = a + b;  //ADD
            `SUB: result = a - b;  //SUB
            `SLL: result = a << b;  //SLL
            `SRL: result = a >> b;  //SRL
            `SRA: result = $signed(a) >>> b[4:0];  //SRA
            `SLT: result = ($signed(a) < $signed(b)) ? 1 : 0;  //SLT
            `SLTU: result = (a < b) ? 1 : 0;  //SLTU
            `XOR: result = a ^ b;  //XOR
            `OR: result = a | b;  //OR
            `AND: result = a & b;  //AND    
            default: result = 32'bx;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] d,
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
    logic [31:0] RegFile[0:2**5-1];
    initial begin
        for (int i = 0; i < 32; i++) begin
            RegFile[i] = 10 + i;
        end

        //RegFile[4] = 32'hFFFF_8001;
        // RegFile[5] = 32'hFFFF_8001;
        // RegFile[6] = 32'hFFFF_8001;
    end

    always_ff @(posedge clk) begin
        if (we) RegFile[WAddr] <= WData;
    end

    assign RData1 = (RAddr1 != 0) ? RegFile[RAddr1] : 32'b0;
    assign RData2 = (RAddr2 != 0) ? RegFile[RAddr2] : 32'b0;
endmodule

module mux_2X1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        case (sel)
            1'b0:    y = x0;
            1'b1:    y = x1;
            default: y = 32'bx;
        endcase
    end
endmodule

module extend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt  //부호 확장의 의미미
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] ifamount = instrCode[14:12];

    assign amount = (ifamount == 3'b001 | ifamount == 3'b101);

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx; 
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            // 0으로 채워지면 음수가 안됨-> {20{instrCode[31]}} 31번 째, 즉 마지막 비트(MSB)를 20번 반복시킨다, 확장시킨다다
            `OP_TYPE_S:
            immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_I: immExt = amount ? {{27{instrCode[31]}}, instrCode[24:20]} : {{20{instrCode[31]}}, instrCode[31:20]};
            default: immExt = 32'bx;
        endcase
    end
endmodule
