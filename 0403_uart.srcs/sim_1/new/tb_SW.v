`timescale 1ns / 1ps

module tb_SW();

    reg clk;
    reg reset;
    reg btn_run;
    reg btn_clear;
    wire [6:0] msec;
    wire [5:0] sec;
    wire [5:0] min;

    top_stopwatch dut (
    .clk(clk),
    .reset(reset),
    .btn_run(btn_run),
    .btn_clear(btn_clear),
    .msec(msec),
    .sec(sec),
    .min(min)
    );

    always #5 clk  = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10;
        reset = 0;

        #500;
        btn_run = 1;
        #1000000000;
        btn_run = 0;
        #5000;
        btn_run = 1;
        #500;
        btn_run = 0;
        #500;
        btn_clear = 1;
        #500;
        btn_clear = 0;
        #500;
        $finish;

    end
endmodule
