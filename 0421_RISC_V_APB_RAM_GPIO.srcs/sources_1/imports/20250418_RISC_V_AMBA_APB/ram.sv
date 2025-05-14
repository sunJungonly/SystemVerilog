`timescale 1ns / 1ps

module ram (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [11:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    logic [31:0] mem[0:2*10-1];

    always_ff @(posedge PCLK) begin
        PREADY <= 1'b0;
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;
            if (PWRITE) mem[PADDR[9:2]] <= PWDATA;  //0, 1, 2뺴야해서
            else PRDATA <= mem[PADDR[9:2]];
        end
    end
endmodule
