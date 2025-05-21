`timescale 1ns / 1ps

module AXI4_Lite_Intf (
    //Global signals
    input            ACLK,
    input            ARESETn,
    //WRITE Transaction, AW Channel
    input      [3:0] AWADDR,
    input            AWVALID,
    output reg       AWREADY,
    //WRITE Transaction, W Channel
    input      [3:0] WDATA,
    input            WVALID,
    output reg       WREADY,
    //WRITE Transaction, B Channel
    output reg [3:0] BRESP,
    output reg       BVALID,
    input            BREADY,
    //READ Transaction, AR channel
    input      [3:0] ARADDR,
    input            ARVALID,
    output reg       ARREADY,
    //READ Transaction, R channel
    output reg [3:0] RDATA,
    output reg       RVALID,
    input            RREADY,
    //internal signals
    output     [2:0] CR,
    output     [7:0] SOD,
    input      [7:0] SID,
    input            SR
);
    wire [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign CR             = slv_reg0[2:0];
    assign SOD            = slv_reg1[7:0];
    assign slv_reg2[31:0] = {24'b0, SID};
    assign slv_reg3[31:0] = {30'b0, SR};

    //WRITE Transaction, AW Channel transfer
    localparam AW_IDLE_S = 0, AW_READY_S = 1;

    reg aw_state, aw_state_next;
    reg [3:0] aw_addr_next, aw_addr_reg;

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always @(*) begin
        aw_state_next = aw_state;
        AWREADY       = 1'b0;
        aw_addr_next  = aw_addr_reg;
        case (aw_state)
            AW_IDLE_S: begin
                AWREADY = 1'b0;
                if (AWVALID) begin
                    aw_state_next = AW_READY_S;
                    aw_addr_next  = AWADDR;
                end
            end
            AW_READY_S: begin
                AWREADY      = 1'b1;
                aw_addr_next = AWADDR;
                if (AWVALID && AWREADY) begin
                    aw_state_next = AW_IDLE_S;
                end
            end
        endcase
    end

    //WRITE Transaction, W Channel transfer
    localparam W_IDLE_S = 0, W_READY_S = 1;

    reg w_state, w_state_next;

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always @(*) begin
        w_state_next = w_state;
        WREADY       = 1'b0;
        case (w_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S: begin
                WREADY = 1'b1;
                if (WVALID) begin
                    w_state_next = W_IDLE_S;
                    case (aw_addr_reg[3:2])
                        2'd0: ; //slv_reg0 = WDATA;
                        2'd1: ; //slv_reg1 = WDATA;
                        2'd2: ; //slv_reg2 = WDATA;
                        2'd3: ; //slv_reg3 = WDATA;
                    endcase
                end
            end
        endcase
    end

    //WRITE Transaction, B Channel transfer
    localparam B_IDLE_S = 0, B_VALID_S = 1;

    reg b_state, b_state_next;

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always @(*) begin
        b_state_next = b_state;
        BRESP        = 2'b00;
        BVALID       = 1'b0;
        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID && WREADY) b_state_next = B_VALID_S;
            end
            B_VALID_S: begin
                BRESP  = 2'b00;  // OK
                BVALID = 1'b1;
                if (BREADY) b_state_next = B_IDLE_S;
            end
        endcase
    end

    //READ Transaction, AR channel
    localparam AR_IDLE_S = 0, AR_READY_S = 1;

    reg ar_state, ar_state_next;
    reg [3:0] ar_addr_next, ar_addr_reg;

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end else begin
            ar_state <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always @(*) begin
        ar_state_next = ar_state;
        ARREADY       = 1'b0;
        ar_addr_next  = ar_addr_reg;
        case (ar_state)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                    ar_addr_next  = ARADDR;
                end
            end
            AR_READY_S: begin
                ARREADY      = 1'b1;
                ar_addr_next = ARADDR;
                if (ARVALID && ARREADY) begin
                    ar_state_next = AR_IDLE_S;
                end
            end
        endcase
    end

    //READ Transaction, R channel
    localparam R_IDLE_S = 0, R_READY_S = 1;

    reg r_state, r_state_next;

    always @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always @(*) begin
        r_state_next = r_state;
        case (r_state)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if (ARVALID && ARREADY) begin
                    r_state_next = R_READY_S;
                end
            end
            R_READY_S: begin
                RVALID = 1'b1;
                if (RREADY) begin
                    r_state_next = R_IDLE_S;
                    case (ar_addr_reg[3:2])
                        2'd0: RDATA = slv_reg0;
                        2'd1: RDATA = slv_reg1;
                        2'd2: RDATA = slv_reg2;
                        2'd3: RDATA = slv_reg3;
                    endcase
                end
            end
        endcase
    end
endmodule
