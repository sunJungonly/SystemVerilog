`timescale 1ns / 1ps

module tb_AXI4_Lite();

    //Global signals
    logic       ACLK;
    logic       ARESETn;
    //WRITE Transaction, AW Channel
    logic [3:0] AWADDR;
    logic       AWVALID;
    logic       AWREADY;
    //WRITE Transaction, W Channel
    logic [3:0] WDATA;
    logic       WVALID;
    logic       WREADY;
    //WRITE Transaction, B Channel
    logic [3:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    //READ Transaction, AR channel
    logic [3:0] ARADDR;
    logic       ARVALID;
    logic       ARREADY;
    //READ Transaction, R channel
    logic   [3:0] RDATA;
    logic         RVALID;
    logic       RREADY;

    //internal signals
    logic        transfer;
    logic        ready;
    logic [ 3:0] addr;
    logic [31:0] wdata;
    logic        write;
    logic [31:0] rdata;

    
    AXI4_Lite_Master dut_master(.*);
    AXI4_Lite_Slave dut_slave (.*);

    always #5 ACLK= ~ACLK;

    initial begin
        ACLK = 0; ARESETn = 0;
        #10 ARESETn = 1;
        
        //write
        @(posedge ACLK);
        #1; addr = 0; wdata = 10; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);
        
        @(posedge ACLK);
        #1; addr = 4; wdata = 11; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 8; wdata = 12; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 12; wdata = 13; write = 1; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        //read
        @(posedge ACLK);
        #1; addr = 0; rdata = 10; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);
        
        @(posedge ACLK);
        #1; addr = 4; rdata = 11; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 8; rdata = 12; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        @(posedge ACLK);
        #1; addr = 12; rdata = 13; write = 0; transfer = 1;
        @(posedge ACLK);
        #1; transfer = 0;
        wait(ready == 1);

        #100;
        $finish;
    end

endmodule
