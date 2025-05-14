`timescale 1ns / 1ps

class transaction;
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  //dut out data
    logic             PREADY;  //dut out data
    // outport signals
    logic      [ 3:0] fndCom;  //dut out data
    logic      [ 7:0] fndFont;  //dut out data

    constraint c_paddr {PADDR inside {4'h0, 4'h4, 4'h8};}
    constraint c_wdata {PWDATA < 10;}

    task display(string name);
        $display(
            "[%s] PADDR = %h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont);
    endtask  //
endclass  //transaction

interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  //dut out data
    logic        PREADY;  //dut out data
    // outport signals
    logic [ 3:0] fndCom;  //dut out data
    logic [ 7:0] fndFont;  //dut out data

endinterface  //APB_Slave_Interface

class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event; //SV에서 제공하는 기능, 대기하는 역할할

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run(int repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();  //make instance
            if (!fnd_tr.randomize()) $error("Randomization fail!");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            @(gen_next_event);  //wait an event from driver
        end
    endtask
endclass  //generator

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            Gen2Drv_mbox.get(fnd_tr);
            fnd_tr.display("DRV");
            //SETUP
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b0;
            fnd_intf.PSEL    <= 1'b1;
            //ACCESS
            @(posedge fnd_intf.PCLK);
            fnd_intf.PADDR   <= fnd_tr.PADDR;
            fnd_intf.PWDATA  <= fnd_tr.PWDATA;
            fnd_intf.PWRITE  <= 1'b1;
            fnd_intf.PENABLE <= 1'b1;
            fnd_intf.PSEL    <= 1'b1;
            wait (fnd_intf.PREADY == 1'b1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            ->gen_next_event;  //event trigger
        end
    endtask

endclass  //driver

class monitor;
    mailbox #(transaction) MonToSCB_mbox;
    virtual APB_Slave_Interface fnd_intf;
    function new(mailbox#(transaction) MonToSCB_mbox,
                 virtual APB_Slave_Interface fnd_intf);
        this.MonToSCB_mbox = MonToSCB_mbox;
        this.fnd_intf = fnd_intf;
    endfunction  //new()

    task run();
        transaction fnd_tr;
        fnd_tr = new();
        forever begin
            @(posedge fnd_intf.PCLK);
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            wait (fnd_intf.PREADY == 1);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            @(posedge fnd_intf.PCLK);
            fnd_tr.PRDATA = fnd_intf.PRDATA;  //dut out data
            fnd_tr.display("MON");
            MonToSCB_mbox.put(fnd_tr);
        end
    endtask
endclass  //monitor

class scoreboard;
    mailbox #(transaction) MonToSCB_mbox;

    logic [7:0] ref_model[0:2**15 - 1];

    function new(mailbox#(transaction) MonToSCB_mbox);
        this.MonToSCB_mbox = MonToSCB_mbox;
        foreach (ref_model[i]) ref_model[i] = 0;
    endfunction  //new()

    task run();
        transaction fnd_tr;
        forever begin
            MonToSCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin
                ref_model[fnd_tr.PADDR] = fnd_tr.PWDATA;
            end else begin
                if (ref_model[fnd_tr.PADDR] === fnd_tr.PRDATA) begin
                    $display("PASS!! Matched Data! ref_model: %h === rData: %h",
                             ref_model[fnd_tr.PADDR], fnd_tr.PRDATA);
                end else begin
                    $display(
                        "FAIL!! Dismatched Data! ref_model: %h === rData: %h",
                        ref_model[fnd_tr.PADDR], fnd_tr.PRDATA);
                end
            end
        end
    endtask
endclass  //monitor



class envirnment;
    mailbox #(transaction) MonToSCB_mbox;
    mailbox #(transaction) Gen2Drv_mbox;
    generator              fnd_gen;
    driver                 fnd_drv;
    monitor                fnd_mon;
    scoreboard             fnd_scb;
    event                  gen_next_event;

    function new(virtual APB_Slave_Interface fnd_intf);
        Gen2Drv_mbox  = new();
        MonToSCB_mbox = new();
        this.fnd_gen  = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv  = new(fnd_intf, Gen2Drv_mbox, gen_next_event);
        this.fnd_mon  = new(MonToSCB_mbox, fnd_intf);
        this.fnd_scb  = new(MonToSCB_mbox);
    endfunction

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
    endtask
endclass  //envirnment

module tb_fndController_APB_Periph ();

    envirnment fnd_env;
    APB_Slave_Interface fnd_intf ();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FndController_Periph dut (
        // global signal
        .PCLK   (fnd_intf.PCLK),
        .PRESET (fnd_intf.PRESET),
        // APB Interface Signals
        .PADDR  (fnd_intf.PADDR),
        .PWDATA (fnd_intf.PWDATA),
        .PWRITE (fnd_intf.PWRITE),
        .PENABLE(fnd_intf.PENABLE),
        .PSEL   (fnd_intf.PSEL),
        .PRDATA (fnd_intf.PRDATA),
        .PREADY (fnd_intf.PREADY),
        // outport signals
        .fndCom (fnd_intf.fndCom),
        .fndFont(fnd_intf.fndFont)
    );

    initial begin
        fnd_intf.PCLK   = 0;
        fnd_intf.PRESET = 1;
        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(10);
        #30;
        $finish;
    end

endmodule
