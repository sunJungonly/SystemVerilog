`timescale 1ns / 1ps

module MCU_SPI (
    input         clk,
    input         rst,
    input         btn,
    input  [13:0] sw,
    //fnd port
    output [ 3:0] com,
    output [ 7:0] font
);

    SPI_master U_SPI_Master (
        .clk   (clk),
        .rst   (rst),
        .btn   (btn),
        .number(sw),
        //slave port
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS  (CS)
    );

    SPI_slave U_SPI_Slave (
        .clk (clk),
        .rst (rst),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS  (CS),
        //fnd port
        .com (com),
        .font(font)
    );
endmodule
