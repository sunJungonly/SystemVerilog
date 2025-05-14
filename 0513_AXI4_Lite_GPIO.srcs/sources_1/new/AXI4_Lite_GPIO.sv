`timescale 1ns / 1ps

module AXI4_Lite_GPIO (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transcation, AW Channel
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transcation, W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transcation, B Channel
    output  logic [ 1:0] BRESP,
    output  logic        BVALID,
    input   logic        BREADY,
    // READ Transcation, AR Channel
    input  logic [ 3:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // READ Transcation, R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP,
    // external port
    inout  logic [ 7:0] io_port
);

    logic [7:0] moder, odr, idr;

    AXI4_Lite_Interface_GPIO U_AXI4_Intf_GPIO (.*);
    gpio_ip U_GPIO (.*);

endmodule

module AXI4_Lite_Interface_GPIO (
    // Global Signals
    input  logic        ACLK,
    input  logic        ARESETn,
    // WRITE Transcation, AW Channel
    input  logic [ 3:0] AWADDR,
    input  logic        AWVALID,
    output logic        AWREADY,
    // WRITE Transcation, W Channel
    input  logic [31:0] WDATA,
    input  logic        WVALID,
    output logic        WREADY,
    // WRITE Transcation, B Channel
    output logic [ 1:0] BRESP,
    output logic        BVALID,
    input  logic        BREADY,
    // READ Transcation, AR Channel
    input  logic [ 3:0] ARADDR,
    input  logic        ARVALID,
    output logic        ARREADY,
    // READ Transcation, R Channel
    output logic [31:0] RDATA,
    output logic        RVALID,
    input  logic        RREADY,
    output logic [ 1:0] RRESP,
    // internal signals
    output logic [ 7:0] moder,
    output logic [ 7:0] odr,
    input  logic [ 7:0] idr
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

    assign moder         = slv_reg0[7:0];
    assign odr           = slv_reg1[7:0];
    assign slv_reg2[7:0] = idr;

    // WRITE Transaction, AW Channel transfer
    typedef enum bit {
        AW_IDLE_S,
        AW_READY_S
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;
    logic [3:0] aw_addr_next, aw_addr_reg;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            aw_state    <= AW_IDLE_S;
            aw_addr_reg <= 0;
        end else begin
            aw_state    <= aw_state_next;
            aw_addr_reg <= aw_addr_next;
        end
    end

    always_comb begin
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
                AWREADY = 1'b1;
                aw_addr_next  = AWADDR; //어차피 같은 값 유지되므로 있어도 되고 없어도 됨
                aw_state_next = AW_IDLE_S;
            end
        endcase
    end

    // WRITE Transaction, W Channel transfer
    typedef enum bit {
        W_IDLE_S,
        W_READY_S
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin
        w_state_next = w_state;
        WREADY       = 1'b0;
        case (aw_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S: begin
                WREADY = 1'b1;  //ready를 먼저 띄움
                if (WVALID) begin
                    w_state_next = W_IDLE_S;
                    case (aw_addr_reg[3:2])
                        2'd0: slv_reg0 = WDATA;
                        2'd1: slv_reg1 = WDATA;
                        2'd2: ;  // idr: read only //slv_reg2 = WDATA;
                        2'd3: slv_reg3 = WDATA;
                    endcase
                end
            end
        endcase
    end

    // WRITE Transaction, B Channel transfer
    typedef enum bit {
        B_IDLE_S,
        B_VALID_S
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin
        b_state_next = b_state;
        BVALID       = 1'b0;
        BRESP        = 2'b00;  //OK
        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID && WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end
            B_VALID_S: begin
                BVALID = 1'b1;  //ready를 먼저 띄움
                BRESP  = 2'b00;  //OK
                if (BREADY) b_state_next = B_IDLE_S;
            end
        endcase
    end

    // READ Transaction, AR Channel transfer
    typedef enum bit {
        AR_IDLE_S,
        AR_READY_S
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;
    logic [3:0] ar_addr_next, ar_addr_reg;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            ar_state    <= AR_IDLE_S;
            ar_addr_reg <= 0;
        end else begin
            ar_state    <= ar_state_next;
            ar_addr_reg <= ar_addr_next;
        end
    end

    always_comb begin
        ar_state_next = ar_state;
        ar_addr_next  = ar_addr_reg;
        ARREADY       = 1'b0;
        case (ar_state)
            AR_IDLE_S: begin
                ARREADY = 1'b0;
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                    ar_addr_next  = ARADDR;
                end
            end
            AR_READY_S: begin
                ARREADY = 1'b1;
                ar_addr_next = ARADDR;
                ar_state_next = AR_IDLE_S;
            end
        endcase
    end

    // READ Transaction, R Channel transfer
    typedef enum bit {
        R_IDLE_S,
        R_VALID_S
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin
        if (!ARESETn) begin
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin
        r_state_next = r_state;
        RVALID       = 1'b0;
        RRESP        = 2'b00;  // OK
        case (r_state)
            R_IDLE_S: begin
                RVALID = 1'b0;
                if (ARVALID && ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end
            R_VALID_S: begin
                RVALID = 1'b1;
                RRESP  = 2'b00;  // OK
                case (ar_addr_reg[3:2])
                    2'd0: RDATA = slv_reg0;
                    2'd1: RDATA = slv_reg1;
                    2'd2: RDATA = slv_reg2;
                    2'd3: RDATA = slv_reg3;
                endcase
                if (RREADY) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end
endmodule

module gpio_ip (
    input  logic [7:0] moder,
    input  logic [7:0] odr,
    output logic [7:0] idr,
    inout  logic [7:0] io_port
);
    genvar i;
    generate
        for (i = 0; i < 8; i++) begin
            assign io_port[i] = moder[i] ? odr[i] : 1'bz;
            assign idr[i]     = ~moder[i] ? io_port[i] : 1'bz;
        end
    endgenerate
endmodule
