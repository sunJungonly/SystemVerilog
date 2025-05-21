`timescale 1ns / 1ps

module Ultrasonic_Periph (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // export signals
    input  logic        echo,
    output logic        trig,
    output logic  [6:0] d_state
);

    logic        usr;  //ultrasonic start register
    logic [11:0] udr;  //ultrasonic distance register

    APB_SlaveIntf_Ultrasonic_Sensor U_APB_Intf_Ultrasonic_Sensor (.*);

    ultrasonic_sensor U_ultrasonic_sensor (
        .clk(PCLK),
        .reset(PRESET),
        .*,
        .error(),
        .done(),
        .d_state(d_state)
    );
endmodule

module APB_SlaveIntf_Ultrasonic_Sensor (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // internal signals
    output logic        usr,      //ultrasonic start register
    input  logic [11:0] udr       //ultrasonic distance register
);
    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2;  // slv_reg3;

    assign usr = slv_reg0[0];
    assign slv_reg1[11:0] = udr;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            //slv_reg1 <= 0;
            //slv_reg2 <= 0;
            // slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;
                        2'd1: ;
                        //2'd2: slv_reg2 <= PWDATA;
                        // 2'd3: slv_reg3 <= PWDATA;
                    endcase
                end else begin
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        //2'd2: PRDATA <= slv_reg2;
                        // 2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end

endmodule





