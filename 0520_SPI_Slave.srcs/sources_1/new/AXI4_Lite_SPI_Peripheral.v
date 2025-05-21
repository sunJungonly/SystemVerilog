`timescale 1ns / 1ps

module AXI4_Lite_SPI_Peripheral(
    //Global signals
    input            ACLK,
    input            ARESETn,
    //WRITE Transaction, AW Channel
    input      [3:0] AWADDR,
    input            AWVALID,
    output reg       AWREADY,
    //WRITE Transaction, W Channel
    input      [3:0] WDATA,
    input            WVALID,
    output reg       WREADY,
    //WRITE Transaction, B Channel
    output reg [3:0] BRESP,
    output reg       BVALID,
    input            BREADY,
    //READ Transaction, AR channel
    input      [3:0] ARADDR,
    input            ARVALID,
    output reg       ARREADY,
    //READ Transaction, R channel
    output reg [3:0] RDATA,
    output reg       RVALID,
    input            RREADY,

    // SPI external port
    output           SCLK,
    output           MOSI,
    input            MISO
    );

    //internal signals
    wire     [2:0] CR;
    wire     [7:0] SOD;
    wire     [7:0] mi_data;
    wire           ready;

    AXI4_Lite_Intf U_AXI4_Lite_Intf(
    .*,
    //internal signals
    output     [2:0] CR(CR),
    output     [7:0] SOD(SOD),
    input      [7:0] SID(mi_data),
    input            SR(ready)
    );

    SPI_Master U_SPI_Master (
    // global signals
    .clk(ACLK),
    .reset(ARESETn),
    // internal signals
    .cpol(CR[0]),
    .cpha(CR[1]),
    .start(CR[2]),
    .tx_data(SOD),
    .rx_data(mi_data),
    .done(),
    .ready(ready),
    // external port
    .*
);
endmodule
