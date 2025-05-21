`timescale 1ns / 1ps

module tb_SPI_Master ();
    logic       clk;
    logic       reset;
    logic       cpol;
    logic       cpha;
    logic       start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic       done;
    logic       ready;
    logic       SCLK;
    logic       MOSI;
    logic       MISO;

    assign MISO = MOSI;

    SPI_Master dut (.*);

    always #5 clk = ~clk;


    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;

        repeat (3) @(posedge clk);

        // address byte
        cs = 1;
        @(posedge clk);
        tx_data = 8'h01; start = 1; cpol = 0; cpha = 0, cs = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x01 address
        @(posedge clk);
        tx_data = 8'h55; start = 1; cpol = 0; cpha = 0, cs = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x02 address //데이터 줄 때마다 addr 1씩 증가
        @(posedge clk);
        tx_data = 8'haa; start = 1; cpol = 0; cpha = 0, cs = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);
        cs = 1;

        #200 $finish;

    end

endmodule
