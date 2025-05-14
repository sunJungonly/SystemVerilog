`timescale 1ns / 1ps


// module tb_fifo();
//     logic clk;
//     logic reset;
//     logic wr_en;
//     logic rd_en;
//     logic [7:0] wData;
//     logic [7:0] rData;
//     logic full;
//     logic empty;

//     fifo dut(.*);

//     always #5 clk = ~clk;
//     initial begin
//         reset = 1; clk = 0;
//         #10 reset = 0;
//         @(posedge clk); #1; wData = 1; wr_en = 1; rd_en = 0;// timing diagram과 맞추기 위한 delay
//         @(posedge clk); #1; wData = 2; wr_en = 1; rd_en = 0; 
//         @(posedge clk); #1; wData = 3; wr_en = 1; rd_en = 0;
//         @(posedge clk); #1; wData = 4; wr_en = 1; rd_en = 0;
//         @(posedge clk); #1; wData = 5; wr_en = 1; rd_en = 0;
//         @(posedge clk); #1; wr_en = 0;
//         @(posedge clk); #1; wr_en = 0; rd_en = 1;// timing diagram과 맞추기 위한 delay
//         @(posedge clk); #1; wr_en = 0; rd_en = 1; 
//         @(posedge clk); #1; wr_en = 0; rd_en = 1;
//         @(posedge clk); #1; wr_en = 0; rd_en = 1;
//         @(posedge clk); #1; wr_en = 0; rd_en = 1;

//         @(posedge clk); #1; wData = 5; wr_en = 1; rd_en = 1;
//         @(posedge clk); #1; wData = 6; wr_en = 1; rd_en = 1;

//         @(posedge clk); #1; wr_en = 0; rd_en = 0;
//         #20; $finish;
//     end
// endmodule

interface fifo_interface (input logic clk, input logic reset);
    logic wr_en;
    logic rd_en;
    logic [7:0] wData;
    logic [7:0] rData;
    logic full;
    logic empty;

    // driver 기준으로 방향을 정한다.
    clocking drv_cb @(posedge clk);  // clocking block
        default input #1 output #1;  // input, output에 1ns delay를 준다.
        output wData, wr_en, rd_en;  // -> input, output을 바로 받으면 data 정하기 어려움
        input rData, full, empty;
    endclocking

    // monitor 기준으로 방향을 정한다.
    clocking mon_cb @(posedge clk); 
        default input #1 output #1;  
        input wData, wr_en, rd_en, rData, full, empty;
    endclocking

    // module에 대한 port(port의 방향성(inout)을 알려준다.)
    modport drv_mport (clocking drv_cb, input reset );    
    modport mon_mport (clocking mon_cb, input reset );

endinterface  //fifo_interface

class transaction;
    rand logic oper; // read/write operator
    rand logic wr_en;
    rand logic rd_en;
    rand logic [7:0] wData;
    logic [7:0] rData;
    logic full;
    logic empty;

    constraint oper_ctrl {oper dist {1 :/ 80, 0 :/ 20};}

    task display(string name);
        $display("[%s] wData=%d, wr_en=%d, full=%d, rData=%d, rd_en=%d, empty=%d, time=%t", name, wData, wr_en,
                 full, rData, rd_en, empty, $time);
    endtask  //
endclass  //transaction

class generator;
    mailbox #(transaction) GenToDrv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) GenToDrv_mbox, event gen_next_event);
        this.GenToDrv_mbox = GenToDrv_mbox;
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

    function new(mailbox#(transaction) GenToDrv_mbox, virtual fifo_interface.drv_mport fifo_if);
        this.GenToDrv_mbox = GenToDrv_mbox;
        this.fifo_if = fifo_if;

    endfunction  //new()

    task write ();
            @(fifo_if.drv_cb);
            fifo_if.drv_cb.wData  <= fifo_tr.wData;
            fifo_if.drv_cb.wr_en  <= 1'b1;
            fifo_if.drv_cb.rd_en  <= 1'b0;
            @(fifo_if.drv_cb);
            fifo_if.drv_cb.wr_en  <= 1'b0;
    endtask //write

    task read ();
            @(fifo_if.drv_cb);
            fifo_if.drv_cb.rd_en  <= 1'b1;
            fifo_if.drv_cb.wr_en  <= 1'b0;
            @(fifo_if.drv_cb);
            fifo_if.drv_cb.rd_en  <= 1'b0;
    endtask //read

    task run();
        forever begin
            GenToDrv_mbox.get(fifo_tr);
            if(fifo_tr.oper) write();
            else read();
            fifo_tr.display("DRV");
        end
    endtask  //

endclass  //driver

class monitor;
    mailbox #(transaction) MonToSCB_mbox;
    virtual fifo_interface.mon_mport fifo_if;
    transaction fifo_tr;

    function new(mailbox#(transaction) MonToSCB_mbox, virtual fifo_interface.mon_mport fifo_if);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.fifo_if = fifo_if;
    endfunction  //new()

    task run();
        forever begin
            @(fifo_if.mon_cb);
            @(fifo_if.mon_cb);
            fifo_tr       = new();
            fifo_tr.wData = fifo_if.mon_cb.wData;
            fifo_tr.wr_en = fifo_if.mon_cb.wr_en;
            fifo_tr.full = fifo_if.mon_cb.full;
            fifo_tr.rData = fifo_if.mon_cb.rData;
            fifo_tr.rd_en = fifo_if.mon_cb.rd_en;
            fifo_tr.empty = fifo_if.mon_cb.empty;

            MonToSCB_mbox.put(fifo_tr);
            fifo_tr.display("MON");
        end
    endtask  //

endclass  //monitor

class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;
    event gen_next_event;
    transaction fifo_tr;
    logic [7:0] scb_fifo[$]; // queue
    logic [7:0] pop_data;


    function new(mailbox#(transaction) MonToSCB_mbox, event gen_next_event);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.gen_next_event = gen_next_event;
    endfunction  //new()

    task run();
        forever begin
            MonToSCB_mbox.get(fifo_tr);
            fifo_tr.display("SCB");
            if (fifo_tr.wr_en) begin
                if(fifo_tr.full == 1'b0) begin
                    scb_fifo.push_back(fifo_tr.wData); // 뒤로 입력
                    $display("[SCB] : DATA Stored in queue : %d, %p\n", fifo_tr.wData, scb_fifo); // fifo 값 전체 출력
                end
                else begin
                    $display("[SCB] : FIFO is full, %p\n", scb_fifo);
                end
            end
            if(fifo_tr.rd_en) begin
                if(fifo_tr.empty == 1'b0) begin
                    pop_data = scb_fifo.pop_front(); // 앞의 값 출력
                    if(fifo_tr.rData == pop_data) begin
                        $display("[SCB] : DATA Matched %d == %d\n", fifo_tr.rData, pop_data);
                    end
                    else begin
                        $display("[SCB] : DATA Mismatched %d != %d\n", fifo_tr.rData, pop_data);
                    end
                end
                else begin
                    $display("[SCB] : FIFO is empty\n");
                end
            end
            ->gen_next_event;
        end
    endtask  
endclass  //scoreboard

class environment;
    mailbox #(transaction) GenToDrv_mbox;
    mailbox #(transaction) MonToSCB_mbox;
    event gen_next_event;
    generator              fifo_gen;
    driver                 fifo_drv;
    monitor                fifo_mon;
    scoreboard             fifo_scb;

    function new(virtual fifo_interface.drv_mport drv_if,
             virtual fifo_interface.mon_mport mon_if);
        GenToDrv_mbox = new();
        MonToSCB_mbox = new();
        fifo_gen = new(GenToDrv_mbox, gen_next_event);
        fifo_drv = new(GenToDrv_mbox, drv_if);
        fifo_mon = new(MonToSCB_mbox, mon_if);
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
endclass  //environment

module tb_fifo ();
    logic clk, reset;

    environment env;
    fifo_interface fifo_if (clk, reset);

    fifo dut (
        .clk(clk),
        .reset(reset),
        .wr_en(fifo_if.wr_en),
        .rd_en(fifo_if.rd_en),
        .wData(fifo_if.wData),
        .rData(fifo_if.rData),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        @(posedge clk);
        reset = 0;
        @(posedge clk);
        env = new(fifo_if.drv_mport, fifo_if.mon_mport);
        env.run(100);
        #50;
        $finish;
    end
endmodule
