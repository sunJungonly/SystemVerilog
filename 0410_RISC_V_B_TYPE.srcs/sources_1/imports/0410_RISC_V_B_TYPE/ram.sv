`timescale 1ns / 1ps

module ram (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:9];

    always_ff @( posedge clk ) begin
        if (we) mem[addr[31:2]] <= wData;
    end
        initial begin
        // for (int i = 0; i < 32; i++) begin
        //     RegFile[i] = 10 + i;
        // end

         mem[13] = 30'h92345678;
    end

    assign rData = mem[addr[31:2]];
endmodule
