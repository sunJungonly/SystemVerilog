`timescale 1ns / 1ps

module FIFO_Status_Register (
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

    logic [7:0] wdata, rdata;
    logic wr_en, rd_en, empty, full;

    APB_SlaveIntf_FIFO U_APB_Intf_FIFO (
        .*,
        .wr_en(wr_en),
        .rd_en(rd_en),
        .fsr({full, empty}),
        .fwd(wdata),
        .frd(rdata) 
    );

    fifo U_FIFO (
        .clk  (PCLK),
        .reset(PRESET),
        // write side
        .wdata(wdata), 
        .wr_en(wr_en), 
        .full (full),
        // read side
        .rdata(rdata),
        .rd_en(rd_en),
        .empty(empty)
    );

endmodule

module APB_SlaveIntf_FIFO (
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
    output logic        wr_en,
    output logic        rd_en,
    // 내부 레지스터
    input  logic [ 1:0] fsr,      //{full, empty}// FIFO 상태 레지스터
    output logic [ 7:0] fwd,      // 쓰기 데이터 레지스터
    input  logic [ 7:0] frd       // 읽기 데이터 레지스터
);

    logic [31:0] slv_reg0, slv_reg1, slv_reg2;  //, slv_reg3;

    assign slv_reg0[1:0] = fsr;
    assign fwd = slv_reg1[7:0];
    assign slv_reg2[7:0] = frd;

    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        READ,
        WAIT
    } state_e;
    state_e state, state_next;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            //slv_reg1 <= 0;
            state <= IDLE;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        PREADY = 1'b0;
        wr_en = 1'b0;
        rd_en = 1'b0;
        slv_reg1 = 0;
        PRDATA = 32'b0;
        case (state)
            IDLE: begin
                PREADY = 1'b0;
                if (PSEL && PENABLE) begin
                    if (PWRITE) begin
                        wr_en = 1'b0;
                        rd_en = 1'b0;
                        state_next = WRITE;
                    end else begin
                        wr_en = 1'b0;
                        rd_en = 1'b0;
                        state_next = READ;
                    end
                end
            end
            WRITE: begin
                if (!fsr[1]) begin  // FIFO가 full이 아닐 때만 쓰기
                    wr_en = 1'b1;
                    rd_en = 1'b0;
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: slv_reg1 = PWDATA;
                        2'd2: ;
                    endcase
                    state_next = WAIT;
                end else begin
                    state_next = IDLE;
                end
            end
            READ: begin
                if (!fsr[0]) begin
                    wr_en  = 1'b0;
                    rd_en  = 1'b1;
                    PRDATA = 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA = slv_reg0;
                        2'd1: PRDATA = slv_reg1;
                        2'd2: PRDATA = slv_reg2;
                    endcase
                    state_next = WAIT;
                end else begin
                    state_next = IDLE;
                end
            end
            WAIT: begin
                wr_en = 1'b0;
                rd_en = 1'b0;
                PREADY = 1'b1;
                state_next = IDLE;
            end
        endcase
    end
endmodule
