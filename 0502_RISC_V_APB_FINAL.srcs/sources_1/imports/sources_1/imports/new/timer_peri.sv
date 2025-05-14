`timescale 1ns / 1ps

module timer_peri (
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
    output logic        PREADY
);

    logic [ 1:0] tcr;
    logic [31:0] tcnt;
    logic [31:0] psc;
    logic [31:0] arr;

    APB_SlaveIntf_Timer U_APB_SlaveIntf_Timer (
        .PCLK(PCLK),
        .PRESET(PRESET),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PENABLE(PENABLE),
        .PSEL(PSEL),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .tcr(tcr),
        .tcnt(tcnt),
        .psc(psc),
        .arr(arr)
    );

    timer U_Timer (
        .clk(PCLK),
        .reset(PRESET),
        .en(tcr[0]),
        .clear(tcr[1]),
        .psc(psc),
        .arr(arr),
        .count(tcnt)
    );
endmodule

module APB_SlaveIntf_Timer (
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
    output logic [ 1:0] tcr,
    input  logic [31:0] tcnt,
    output logic [31:0] psc,
    output logic [31:0] arr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign tcr = slv_reg0[1:0];
    assign slv_reg1 = tcnt;
    assign psc = slv_reg2;
    assign arr = slv_reg3;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            // slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    PREADY <= 1'b1;
                    case (PADDR[3:2])
                        2'd0: slv_reg0 <= PWDATA;  // Timer control register(0x00)
                        // 2'd1: slv_reg1 <= PWDATA;  // Timer Count register(0x04)
                        2'd2: slv_reg2 <= PWDATA;  // Prescaler register(0x08)
                        2'd3: slv_reg3 <= PWDATA;  // Auto-Reload register(0x12)
                    endcase
                end else begin
                    PREADY <= 1'b1;
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA <= slv_reg0;
                        2'd1: PRDATA <= slv_reg1;
                        2'd2: PRDATA <= slv_reg2;
                        2'd3: PRDATA <= slv_reg3;
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule

module timer (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic        clear,
    input  logic [31:0] psc,
    input  logic [31:0] arr,
    output logic [31:0] count
);

    logic tick_1khz;

    clk_div_1khz U_PSC (
        .clk(clk),
        .reset(reset),
        .en(en),
        .clear(clear),
        .psc(psc),
        .o_tick(tick_1khz)
    );

    count_timer U_TCNT (
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(tick_1khz),
        .arr(arr),
        .count(count)
    );
endmodule

module clk_div_1khz (
    input logic clk,
    input logic reset,
    input logic en,
    input logic clear,
    input logic [31:0] psc,
    output logic o_tick
);
    logic [31:0] count_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (en) begin
                if (count_reg == psc) begin
                    count_reg <= 0;
                    o_tick <= 1'b1;
                end else begin
                    count_reg <= count_reg + 1;
                    o_tick <= 1'b0;
                end
            end
            if (clear) begin
                count_reg <= 0;
                o_tick <= 1'b0;
            end
        end
    end
endmodule

module count_timer (
    input logic clk,
    input logic reset,
    input logic clear,
    input logic i_tick,
    input logic [31:0] arr,
    output logic [31:0] count
);

    always_ff @(posedge clk) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (i_tick) begin
                if (count == arr) begin
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
                if (clear) begin
                    count <= 0;
                end
            end
        end
    end
endmodule
