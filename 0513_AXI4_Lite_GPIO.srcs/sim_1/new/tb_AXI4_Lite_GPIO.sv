`timescale 1ns / 1ps

module tb_AXI4_Lite_GPIO();
    // Global Signals
    logic        ACLK;
    logic        ARESETn;
    // WRITE Transcation, AW Channel
    logic [ 3:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;
    // WRITE Transcation, W Channel
    logic [31:0] WDATA;
    logic        WVALID;
    logic        WREADY;
    // WRITE Transcation, B Channel
    logic [ 1:0] BRESP;
    logic        BVALID;
    logic        BREADY;
    // READ Transcation, AR Channel
    logic [ 3:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;
    // READ Transcation, R Channel
    logic [31:0] RDATA;
    logic        RVALID;
    logic        RREADY;
    logic [ 1:0] RRESP;
    // external port
    wire [ 7:0] io_port;

    AXI4_Lite_GPIO dut (.*);

    always #5 ACLK = ~ACLK;

    // external port
    logic [7:0] io_port_input;
    logic [7:0] io_port_mode;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gpio
            assign io_port[i] = (io_port_mode[i] == 0) ? io_port_input[i] : 1'bz;
        end
    endgenerate

    initial begin
        ACLK = 0; ARESETn = 0;
        #10 ARESETn = 1;
        @(posedge ACLK);
        #1; AWADDR = 0; AWVALID = 1; WDATA = 8'hff; WVALID = 1; BREADY = 1;
        wait(WVALID && WREADY); 
        @(posedge ACLK);
        AWVALID = 0; WVALID = 0;
        wait(BVALID == 1);
        @(posedge ACLK);
        BREADY = 0;
        @(posedge ACLK);

        @(posedge ACLK);
        #1; AWADDR = 4; AWVALID = 1; WDATA = 8'haa; WVALID = 1; BREADY = 1;
        wait(WVALID && WREADY); 
        @(posedge ACLK);
        AWVALID = 0; WVALID = 0;
        wait(BVALID == 1);
        @(posedge ACLK);
        BREADY = 0;
        @(posedge ACLK);

        @(posedge ACLK);
        #1; AWADDR = 4; AWVALID = 1; WDATA = 8'h55; WVALID = 1; BREADY = 1;
        wait(WVALID && WREADY); 
        @(posedge ACLK);
        AWVALID = 0; WVALID = 0;
        wait(BVALID == 1);
        @(posedge ACLK);
        BREADY = 0;
        @(posedge ACLK);

        @(posedge ACLK);
        #1; AWADDR = 0; AWVALID = 1; WDATA = 8'h00; WVALID = 1; BREADY = 1;
        wait(WVALID && WREADY); 
        @(posedge ACLK);
        AWVALID = 0; WVALID = 0;
        wait(BVALID == 1);
        @(posedge ACLK);
        BREADY = 0;
        @(posedge ACLK);
        
        io_port_mode = 8'h00;
        io_port_input = 8'h12;

        @(posedge ACLK);
        #1; ARADDR = 8; ARVALID = 1; RREADY = 1;
        wait(ARREADY); 
        @(posedge ACLK);
        ARVALID = 0;
        wait(RVALID)
        @(posedge ACLK);
        RREADY = 0;
        @(posedge ACLK);

        io_port_mode = 8'h00;
        io_port_input = 8'h34;

        @(posedge ACLK);
        #1; ARADDR = 8; ARVALID = 1; RREADY = 1;
        wait(ARREADY); 
        @(posedge ACLK);
        ARVALID = 0;
        wait(RVALID)
        @(posedge ACLK);
        RREADY = 0;
        @(posedge ACLK);
        #50 $finish;

    end
    
endmodule
