`timescale 1ns / 1ps

module tb_fndctrl();

    logic        PCLK;
    logic        PRESET;
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic [ 3:0] fndCom;
    logic [ 7:0] fndFont;

    always #5 PCLK = ~PCLK;

    FndController_Periph U_fndDUT (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );  

    initial begin
        PCLK = 0; PRESET = 1;
        #10 PRESET = 0;
        #100;
        @(posedge PCLK);
        PADDR   = 4'h4;
        PWDATA  = 14'd1234;
        PWRITE  = 1'b1;
        PENABLE = 1'b0;
        PSEL    = 1'b1;
        @(posedge PCLK);
        PADDR   = 4'h4;
        PWDATA  = 14'd1234;
        PWRITE  = 1'b1;
        PENABLE = 1'b1;
        PSEL    = 1'b1;
        // @(PREADY == 1'b1);
        #30;
        $finish;
    end
endmodule
