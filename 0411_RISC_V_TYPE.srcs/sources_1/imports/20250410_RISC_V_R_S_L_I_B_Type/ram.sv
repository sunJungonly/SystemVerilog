`timescale 1ns / 1ps

module ram (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:63];

    always_ff @( posedge clk ) begin
        if (we) mem[addr[31:2]] <= wData;
    end

    // initial begin
    //     mem[2] = 32'hFFFF_1234;
    //     mem[3] = 32'hFFFF_8294;
    //     mem[4] = 32'hFFFF_8234;
    // end

    assign rData = mem[addr[31:2]];

endmodule


