`timescale 1ns / 1ps
/*
module tb_fifo ();
    logic       clk;
    logic       reset;
    // write side
    logic [7:0] wdata;
    logic       wr_en;
    logic       full;
    // read side
    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;

    fifo dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;
        @(posedge clk);
        #1;
        wdata = 1;
        wr_en = 1;
        rd_en = 0;
        @(posedge clk);
        #1;
        wdata = 2;
        wr_en = 1;
        rd_en = 0;
        @(posedge clk);
        #1;
        wdata = 3;
        wr_en = 1;
        rd_en = 0;
        @(posedge clk);
        #1;
        wdata = 4;
        wr_en = 1;
        rd_en = 0;
        @(posedge clk);
        #1;
        wdata = 5;
        wr_en = 1;
        rd_en = 0;
        @(posedge clk);
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 1;
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 1;
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 1;
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 1;
        @(posedge clk);
        #1;
        wr_en = 0;
        rd_en = 1;
        #20;
        $finish;

    end
endmodule
*/


interface fifo_interface (
    input logic clk,
    input logic reset
);
    // write side
    logic [7:0] wdata;
    logic       wr_en;
    logic       full;
    // read side
    logic [7:0] rdata;
    logic       rd_en;
    logic       empty;

    clocking drv_cb @(posedge clk); // test bench 기준으로 방향을 정한다.
        default input #1 output #1;
        // write side
        output wdata;
        output wr_en;
        input full;
        // read side
        input rdata;
        output rd_en;
        input empty;
    endclocking

    clocking mon_cb @(posedge clk); // test bench 기준으로 방향을 정한다.
        default input #1 output #1;
        // write side
        input wdata;
        input wr_en;
        input full;
        // read side
        input rdata;
        input rd_en;
        input empty;
    endclocking

    modport drv_mport(clocking drv_cb, input reset);
    modport mon_mport(clocking mon_cb, input reset);

endinterface  //fifo_interface

class transaction;
    rand logic       oper;  //read /write operator
    // write side
    rand logic [7:0] wdata;
    rand logic       wr_en;
    logic            full;
    // read side
    logic      [7:0] rdata;
    rand logic       rd_en;
    logic            empty;

    constraint oper_ctrl {oper dist { 1 :/ 80, 0:/ 20};}
    
    task display(string name);
        $display(
            "[%S] oper=%d, wdata=%d, wr_en=%d, full=%d, rdata=%d, rd_en=%d, empty=%d",
            name, oper, wdata, wr_en, full, rdata, rd_en, empty);
    endtask  //

endclass  //transaction

class generator;
    mailbox #(transaction) GenToDrv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) GenToDrv_mbox, event gen_next_event);
        this.GenToDrv_mbox  = GenToDrv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run(int repeat_counter);
        transaction fifo_tr;
        repeat (repeat_counter) begin
            fifo_tr = new();
            if (!fifo_tr.randomize()) $error("Randomization failed!!!");
            fifo_tr.display("GEN");
            GenToDrv_mbox.put(fifo_tr);
            @(gen_next_event);
        end
    endtask  //
endclass  //generator

class driver;
    mailbox #(transaction) GenToDrv_mbox;
    virtual fifo_interface.drv_mport fifo_if;
    transaction fifo_tr;

    function new(mailbox#(transaction) GenToDrv_mbox,
                 virtual fifo_interface.drv_mport fifo_if);
        this.GenToDrv_mbox = GenToDrv_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()    

    task write();
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.wdata <= fifo_tr.wdata;
        fifo_if.drv_cb.wr_en <= 1'b1;
        fifo_if.drv_cb.rd_en <= 1'b0;
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.wr_en <= 1'b0;
    endtask

    task read();
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.wdata <= fifo_tr.wdata;
        fifo_if.drv_cb.rd_en <= 1'b1;
        fifo_if.drv_cb.wr_en <= 1'b0;
        @(fifo_if.drv_cb);
        fifo_if.drv_cb.rd_en <= 1'b0;
    endtask

    task run();
        forever begin
            GenToDrv_mbox.get(fifo_tr);
            if (fifo_tr.oper == 1'b1) write();
            else read();
            fifo_tr.display("DRV");
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) MonToSCB_mbox;
    virtual fifo_interface.mon_mport fifo_if;
    transaction fifo_tr;

    function new(mailbox#(transaction) MonToSCB_mbox,
                 virtual fifo_interface.mon_mport fifo_if);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(fifo_if.mon_cb);
            @(fifo_if.mon_cb);
            fifo_tr       = new();
            fifo_tr.wdata = fifo_if.mon_cb.wdata;
            fifo_tr.wr_en = fifo_if.mon_cb.wr_en;
            fifo_tr.full  = fifo_if.mon_cb.full;

            fifo_tr.rdata = fifo_if.mon_cb.rdata;
            fifo_tr.rd_en = fifo_if.mon_cb.rd_en;
            fifo_tr.empty = fifo_if.mon_cb.empty;

            MonToSCB_mbox.put(fifo_tr);
            fifo_tr.display("MON");
        end
    endtask
endclass  //monitor

class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;
    event gen_next_event;
    transaction fifo_tr;
    logic [7:0] scb_fifo[$];  // $ : 무한대로 만듦
    logic [7:0] pop_data;

    function new(mailbox#(transaction) MonToSCB_mbox, event gen_next_event);
        this.MonToSCB_mbox  = MonToSCB_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            MonToSCB_mbox.get(fifo_tr);
            fifo_tr.display("SCB");
            if (fifo_tr.wr_en == 1'b1) begin
                if (fifo_tr.full == 1'b0) begin
                    scb_fifo.push_back(fifo_tr.wdata);
                    $display("[SCB] : DATA Stored in quene : %d, %p",
                             fifo_tr.wdata, scb_fifo);
                end else begin
                    $display("[SCB] : FIFO is full, %p", scb_fifo);
                end
            end
            if (fifo_tr.rd_en == 1'b1) begin
                if (fifo_tr.empty == 1'b0) begin
                    pop_data = scb_fifo.pop_front();
                    if (fifo_tr.rdata == pop_data) begin
                        $display("[SCB] : DATA Matched %d == %d",
                                 fifo_tr.rdata, pop_data);
                    end else begin
                        $display("[SCB] : DATA Mismatched %d != %d",
                                 fifo_tr.rdata, pop_data);
                    end
                end else begin
                    $display("[SCB] : FIFO is empty!");
                end
            end
            -> gen_next_event;
        end
    endtask  //
endclass  //scoreboard

class envirnment;
    mailbox #(transaction) GenToDrv_mbox;
    mailbox #(transaction) MonToSCB_mbox;
    event                  gen_next_event;
    generator              fifo_gen;
    driver                 fifo_drv;
    monitor                fifo_mon;
    scoreboard             fifo_scb;

    function new(virtual fifo_interface fifo_if);
        GenToDrv_mbox = new();
        MonToSCB_mbox = new();
        fifo_gen = new(GenToDrv_mbox, gen_next_event);
        fifo_drv = new(GenToDrv_mbox, fifo_if);
        fifo_mon = new(MonToSCB_mbox, fifo_if);
        fifo_scb = new(MonToSCB_mbox, gen_next_event);
    endfunction  //new()

    task run(int count);
        fork
            fifo_gen.run(count);
            fifo_drv.run();
            fifo_mon.run();
            fifo_scb.run();
        join_any
    endtask  //
endclass  //envirnment

module tb_fifo ();
    logic clk, reset;

    envirnment env;
    fifo_interface fifo_if (
        clk,
        reset
    );

    fifo dut (
        .clk  (clk),
        .reset(reset),
        .wdata(fifo_if.wdata),
        .wr_en(fifo_if.wr_en),
        .full (fifo_if.full),
        .rdata(fifo_if.rdata),
        .rd_en(fifo_if.rd_en),
        .empty(fifo_if.empty)
    );


    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        env = new(fifo_if);
        env.run(100);
        #50;
        $finish;
    end

endmodule
