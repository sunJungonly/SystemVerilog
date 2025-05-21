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
    logic       SS;


    SPI_Master master_dut (.*);

    SPI_Slave slave_dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;
        SS = 1;
        repeat (3) @(posedge clk);

        // address byte
        SS = 0;
        @(posedge clk);
        tx_data = 8'b10000000; //write
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x00 address //데이터 줄 때마다 addr 1씩 증가
        @(posedge clk);
        tx_data = 8'h10;
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x01 address 
        @(posedge clk);
        tx_data = 8'h20;
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x02 address
        @(posedge clk);
        tx_data = 8'h30;
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        //write data byte on 0x03 address
        @(posedge clk);
        tx_data = 8'h40;
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);
        @(posedge clk);

        SS = 1;

        repeat (5) @(posedge clk);

        SS = 0;
        @(posedge clk);
        tx_data = 8'b00000000;
        start = 1;
        cpol = 0;
        cpha = 0;
        @(posedge clk);
        start = 0;
        wait (done == 1);

        for (int i = 0; i <4; i ++) begin
            tx_data = 8'hff;
            start = 1;
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            wait (done == 1);
            @(posedge clk);
        end

        SS = 1;


        #200 $finish;

    end

endmodule
