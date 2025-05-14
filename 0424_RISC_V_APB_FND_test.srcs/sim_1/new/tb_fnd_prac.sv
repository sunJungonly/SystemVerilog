`timescale 1ns / 1ps   

class transaction;
    // APB Interface Signals
    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;
    logic             PREADY;
    // outport signals
    logic      [ 3:0] fndCom;
    logic      [ 7:0] fndFont;

    task display(string name);
        $display(
            "[%s] PADDR = %h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, fndCom=%h, fndFont=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, fndCom,
            fndFont);
    endtask
endclass  //transaction

interface APB_Slave_Interface;
    // global signal
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals
    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;
    logic        PREADY;
    // outport signals
    logic [ 3:0] fndCom;
    logic [ 7:0] fndFont;
endinterface  //APB_Slave_Interface


class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run(repeat_counter);
        transaction fnd_tr;
        repeat (repeat_counter) begin
            fnd_tr = new();
            if (!fnd_tr.randomize()) $error("Randomization fail!");
            fnd_tr.display("GEN");
            Gen2Drv_mbox.put(fnd_tr);
            #10;
            @(gen_next_event);
        end
    endtask  //
endclass  //generator

class driver;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Gen2Drv_mbox;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.fnd_intf = fnd_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction  //new()

    task run();
        transaction fnd_tr;
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
            wait (fnd_tr.PREADY == 1'b1);
        end
    endtask  //
endclass  // driver

class monitor;
    virtual APB_Slave_Interface fnd_intf;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;

    function new(virtual APB_Slave_Interface fnd_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.fnd_intf = fnd_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction

    task run();
        forever begin
            fnd_tr = new();
            wait (fnd_intf.PREADY == 1'b1);
            fnd_tr.PADDR   = fnd_intf.PADDR;
            fnd_tr.PWDATA  = fnd_intf.PWDATA;
            fnd_tr.PWRITE  = fnd_intf.PWRITE;
            fnd_tr.PENABLE = fnd_intf.PENABLE;
            fnd_tr.PSEL    = fnd_intf.PSEL;
            fnd_tr.PRDATA    = fnd_intf.PRDATA;
            fnd_tr.PREADY    = fnd_intf.PREADY;
            fnd_tr.fndCom    = fnd_intf.fndCom;
            fnd_tr.fndFont    = fnd_intf.fndFont;
            Mon2SCB_mbox.put(fnd_tr);
            fnd_tr.display("MON");
            @(posedge fnd_intf.PCLK);
        end
    endtask
endclass  //monitor

class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction fnd_tr;
    event gen_next_event;

    //reference model
    logic [31:0] refFndReg [0:2];
    logic [ 3:0] refFndCom [0:3] = '
    {
        4'b1110,
        4'b1101,
        4'b1011,
        4'b0111
    };
    logic [ 7:0] refFndFont[0:15] = '{
        8'hc0,
        8'hf9,
        8'ha4,
        8'hb0,
        8'h99,
        8'h92,
        8'h82,
        8'hf8,
        8'h80,
        8'h90,
        8'h88,
        8'h83,
        8'hc6,
        8'ha1,
        8'h86,
        8'h8e
    };

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox   = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;

        for(int i=0; i<3; i++) begin
            refFndReg[i] = 0;
        end
    endfunction  

    task run();
        int value;
        int font_1, font_10, font_100, font_1000;
        logic [7:0] digit_1, digit_10, digit_100, digit_1000;

        forever begin
            Mon2SCB_mbox.get(fnd_tr);
            fnd_tr.display("SCB");
            if (fnd_tr.PWRITE) begin
                refFndReg[fnd_tr.PADDR[3:2]] = fnd_tr.PWDATA;

                value = refFndReg[1]; 
                font_1    = value % 10;
                font_10   = (value / 10) % 10;
                font_100  = (value / 100) % 10;
                font_1000 = (value / 1000) % 10;

                digit_1    = refFndFont[font_1];
                digit_10   = refFndFont[font_10];
                digit_100  = refFndFont[font_100];
                digit_1000 = refFndFont[font_1000];


                    case (fnd_tr.fndCom)
                        4'b1110: if ({refFndReg[2][0], digit_1[6:0]} == fnd_tr.fndFont[7:0])
                                $display("FND Com 4'b1110 PASS!!!, %h, %h",
                                            {refFndReg[2][0], digit_1[6:0]}, fnd_tr.fndFont[7:0]); 
                                else 
                                $display("FND Com 4'b1110 FAIL!!!, %h, %h",
                                            {refFndReg[2][0], digit_1[6:0]}, fnd_tr.fndFont[7:0]); 
                        4'b1101: if ({refFndReg[2][1], digit_10[6:0]} == fnd_tr.fndFont[7:0])
                                $display("FND Com 4'b1101 PASS!!!, %h, %h",
                                            {refFndReg[2][1], digit_10[6:0]}, fnd_tr.fndFont[7:0]); 
                                else 
                                $display("FND Com 4'b1101 FAIL!!!, %h, %h",
                                            {refFndReg[2][1], digit_10[6:0]}, fnd_tr.fndFont[7:0]); 
                        4'b1011: if ({refFndReg[2][2], digit_100[6:0]} == fnd_tr.fndFont[7:0])
                                $display("FND Com 4'b1011 PASS!!!, %h, %h",
                                            {refFndReg[2][2], digit_100[6:0]}, fnd_tr.fndFont[7:0]); 
                                else 
                                $display("FND Com 4'b1011 FAIL!!!, %h, %h",
                                            {refFndReg[2][2], digit_100[6:0]}, fnd_tr.fndFont[7:0]); 
                        4'b0111: if ({refFndReg[2][3], digit_1000[6:0]} == fnd_tr.fndFont[7:0])
                                $display("FND Com 4'b0111 PASS!!!, %h, %h",
                                            {refFndReg[2][3], digit_1000[6:0]}, fnd_tr.fndFont[7:0]); 
                                else 
                                $display("FND Com 4'b0111 FAIL!!!, %h, %h",
                                            {refFndReg[2][0], digit_1000[6:0]}, fnd_tr.fndFont[7:0]); 
                        //en = 0
                        4'b1111: if (refFndReg[0] == 0) begin
                                    if (4'hf == fnd_tr.fndCom)
                                        $display("FND Enable PASS!!!");
                                    else $display("FND Enable FAIL!!!");
                                end
                    endcase
            end
            else begin  // read mode
            end 
            ->gen_next_event;  //event trigger
    end
    endtask
endclass  //scoreboard

class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;

    generator  fnd_gen;
    driver     fnd_drv;         
    monitor    fnd_mon;          
    scoreboard fnd_scb;          
    event      gen_next_event;     

    function new(virtual APB_Slave_Interface fnd_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.fnd_gen      = new(Gen2Drv_mbox, gen_next_event);
        this.fnd_drv      = new(fnd_intf, Gen2Drv_mbox);
        this.fnd_mon      = new(fnd_intf, Mon2SCB_mbox);
        this.fnd_scb      = new(Mon2SCB_mbox, gen_next_event);
    endfunction 

    task run(int count);
        fork
            fnd_gen.run(count);
            fnd_drv.run();
            fnd_mon.run();
            fnd_scb.run();
        join_any
        ;
    endtask
endclass //envirnment

module tb_fnd_prac ();

    envirnment fnd_env;

    APB_Slave_Interface fnd_intf ();

    always #5 fnd_intf.PCLK = ~fnd_intf.PCLK;

    FndController_Periph dut (
        // global signal
        .PCLK   (fnd_intf.PCLK),
        .PRESET (fnd_intf.PRESET),
        // APB Interface Signals
        .PADDR  (4'h4), //fnd_intf.PADDR
        .PWDATA (14'd1234), //fnd_intf.PADDR
        .PWRITE (1'b1), // fnd_intf.PWRITE
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
        $display("start!");

        #10 fnd_intf.PRESET = 0;
        fnd_env = new(fnd_intf);
        fnd_env.run(100);
        #30;
        $display("finished!");
        $finish;
    end
endmodule





                // // FndFont 비교 
                // if (refFndFont[refFndReg[1][6:0]] == fnd_tr.fndFont[6:0]) 
                //     $display("FND Font PASS!!!, %h, %h",
                //     refFndFont[refFndReg[1][6:0]], 
                //     fnd_tr.fndFont[6:0]); 
                // else  
                //     $display("FND Font FAIL!!!, %h, %h",
                //     refFndFont[refFndReg[1][6:0]], 
                //     fnd_tr.fndFont[6:0]); 
                // // en = 0,  fndcom ==4'b1111(=4'hf);
                // if (refFndReg[0] == 0) begin
                //     if (4'hf == fnd_tr.fndCom)
                //         $display("FND Enable PASS!!!");
                //     else $display("FND Enable FAIL!!!");
                // end
                // else begin //en = 0,  FndCom과 FndFont 각 자리 비교
                //     if (refFndReg[1                 ])
                // end
                
                
                // // FndCom과 FndFont 각 자리 비교
                // if (refFndCom[0:3] == fnd_tr.fndCom)
                //     $display("FND Com PASS!!!, %h, %h",
                //     refFndCom[0:3], 
                //     fnd_tr.fndCom[3:0]); 
                // else  
                //     $display("FND Com FAIL!!!, %h, %h",
                //     refFndCom[0:3], 
                //     fnd_tr.fndCom[3:0]); 
                
                // // FndDot 비교 
                // if (refFndFont[refFndReg[1][7]] == fnd_tr.fndFont[7]) 
                //     $display("FND Dot PASS!!!, %h, %h",
                //     refFndFont[refFndReg[1][7]], 
                //     fnd_tr.fndFont[7]); 
                // else  
                //     $display("FND Dot FAIL!!!, %h, %h",
                //     refFndFont[refFndReg[1][7]], 
                //     fnd_tr.fndFont[7]); 