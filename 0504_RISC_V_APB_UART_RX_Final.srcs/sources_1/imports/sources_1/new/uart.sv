`timescale 1ns / 1ps

module Uart_RX_Periph (
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
    input  logic        RX
);
    logic full, empty, wr_en, rd_en;  //, tx_done, fifo_tx_empty;
    logic [7:0] rx_data, fifo_rdata, fifo_tx_rdata;


    APB_SlaveIntf_UART U_APB_Intf (
        .*,
        // internal signals
        //.wr_en(wr_en),
        .rd_en(rd_en),
        .fsr  ({full, empty}),
        .frd  (fifo_rdata)
    );

    fifo U_FIFO_RX (
        .clk  (PCLK),
        .reset(PRESET),
        // write side
        .wdata(rx_data),
        .wr_en(rx_done),
        .full (full),
        // read side
        .rdata(fifo_rdata),
        .rd_en(rd_en),
        .empty(empty)
    );


    uart U_UART (
        //global port
        .clk(PCLK),
        .reset(PRESET),
        // rx side port
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .rx(RX)
    );

endmodule



module APB_SlaveIntf_UART (
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
    //output logic        wr_en,
    output logic        rd_en,
    // 내부 레지스터
    input  logic [ 1:0] fsr,      //{full, empty}// FIFO 상태 레지스터
    //output logic [ 7:0] fwd,      // 쓰기 데이터 레지스터
    input  logic [ 7:0] frd       // 읽기 데이터 레지스터
);

    logic [31:0] slv_reg0, slv_reg1;  //, slv_reg2;  //, slv_reg3;

    assign slv_reg0[31:0] = {30'b0, fsr};
    //assign fwd = slv_reg1[7:0];
    assign slv_reg1[31:0] = {24'b0, frd};
    typedef enum logic [1:0] {
        IDLE,
        WRITE,
        READ
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
        //wr_en = 1'b0;
        rd_en = 1'b0;
        //slv_reg1 = 0;
        PRDATA = 32'b0;
        case (state)
            IDLE: begin
                PREADY = 1'b0;
                if (PSEL && PENABLE) begin
                    if (PWRITE) begin
                        //wr_en = 1'b0;
                        rd_en = 1'b0;
                        state_next = WRITE;
                    end else begin
                        //wr_en = 1'b0;
                        rd_en = 1'b0;
                        state_next = READ;
                    end
                end
            end
            WRITE: begin
                if (!fsr[1]) begin  // FIFO가 full이 아닐 때만 쓰기
                    //wr_en = 1'b1;
                    rd_en  = 1'b0;
                    PREADY = 1'b1;
                    case (PADDR[3:2])
                        2'd0: ;
                        2'd1: ;  //slv_reg1 = PWDATA;
                        //2'd2: ;
                    endcase
                    state_next = IDLE;
                end else begin
                    state_next = IDLE;
                end
            end
            READ: begin
                if (!fsr[0]) begin  // FIFO가 empty가 아닐 때만 쓰기
                    //wr_en  = 1'b0;
                    rd_en  = 1'b1;
                    PREADY = 1'b1;
                    PRDATA = 32'bx;
                    case (PADDR[3:2])
                        2'd0: PRDATA = slv_reg0;
                        2'd1: PRDATA = slv_reg1;
                        //2'd2: PRDATA = slv_reg2;
                    endcase
                    state_next = IDLE;
                end else begin
                    state_next = IDLE;
                end
            end
        endcase
    end
endmodule


module uart_rx (
    //global port
    input  logic       clk,
    input  logic       reset,
    // //tx side port
    // input  [7:0] tx_data,
    // input        tx_start,
    // output       tx_busy,
    // output       tx_done,
    // output       tx,
    // rx side port
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_busy,
    input  logic       rx
);

    wire br_tick;

    baudrate_gen U_BaudRate_Gen (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick)
    );


    recevier U_Receiver (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .rx     (rx)
    );

    // transmitter U_Transmitter (
    //     .clk     (clk),
    //     .reset   (reset),
    //     .tx_data (tx_data),
    //     .tx_start(tx_start),
    //     .br_tick (br_tick),
    //     .tx_busy (tx_busy),
    //     .tx_done (tx_done),
    //     .tx      (tx)
    // );

endmodule


// typedef enum logic [1:0] {
//     IDLE,
//     ACCESS
//     // WRITE,
//     // READ,
//     // WAIT
// } state_e;
// state_e state, state_next;

// always_ff @(posedge PCLK, posedge PRESET) begin
//     if (PRESET) begin
//         //slv_reg1 <= 0;
//         state <= IDLE;
//     end else begin
//         state <= state_next;
//     end
// end


// always_comb begin
//     state_next = state;
//     PREADY = 0;
//     rd_en = 0;
//     PRDATA = 32'b0;

//     case (state)
//         IDLE: begin
//             if (PSEL && PENABLE) begin
//                 state_next = ACCESS;
//             end
//         end
//         ACCESS: begin
//             state_next = IDLE;
//             PREADY = 1;
//             if (PWRITE) begin
//                 if (!fsr[1]) begin  // FIFO가 full이 아닐 때만 쓰기
//                 case (PADDR[3:2])
//                     2'b00: ;
//                     2'b01: ;                               
//                 endcase
//                 end
//             end else begin
//                 if (!fsr[0]) begin
//                 case (PADDR[3:2])
//                     2'b00: PRDATA = slv_reg0;
//                     2'b01:begin 
//                     PRDATA = slv_reg1;
//                     rd_en = 1;
//                     end
//                 endcase
//                 end
//             end
//             end
//     endcase
// end

// always_comb begin
//     state_next = state;
//     PREADY = 1'b0;
//     //wr_en = 1'b0;
//     rd_en = 1'b0;
//     //slv_reg1 = 0;
//     PRDATA = 32'b0;
//     case (state)
//         IDLE: begin
//             PREADY = 1'b0;
//             if (PSEL && PENABLE) begin
//                 if (PWRITE) begin
//                     //wr_en = 1'b0;
//                     rd_en = 1'b0;
//                     state_next = WRITE;
//                 end else begin
//                     //wr_en = 1'b0;
//                     rd_en = 1'b0;
//                     state_next = READ;
//                 end
//             end
//         end
//         WRITE: begin
//             if (!fsr[1]) begin  // FIFO가 full이 아닐 때만 쓰기
//                 //wr_en = 1'b1;
//                 rd_en = 1'b0;
//                 case (PADDR[3:2])
//                     2'd0: ;
//                     2'd1: ; 
//                     //2'd2: ;
//                 endcase
//                 state_next = WAIT;
//             end else begin
//                 state_next = IDLE;
//             end
//         end

//         READ: begin
//             case (PADDR[3:2])
//                 2'd0: begin  // FSR 읽기 → 항상 응답
//                     PREADY = 1'b1;
//                     PRDATA = slv_reg0;
//                     rd_en = 1'b0;
//                     state_next = WAIT;  // 정상 응답
//                 end

//                 2'd1: begin  // FRD 읽기 → FIFO에 데이터 있어야만 응답
//                     if (!fsr[0]) begin
//                         PREADY = 1'b1;
//                         PRDATA = {25'b0, slv_reg1[7:0]};
//                         rd_en = 1'b1;
//                         state_next = WAIT;  // 정상 응답
//                     end else begin
//                         // FIFO 비어 있으면 응답하지 않고 IDLE로 빠짐
//                         state_next = IDLE;
//                     end
//                 end

//                 default: begin
//                     state_next = IDLE;  // 예외 주소 처리
//                 end
//             endcase
//         end


// READ: begin
//     if (!fsr[0]) begin // FIFO가 empty가 아닐 때만 읽읽기
//         //wr_en  = 1'b0;
//         rd_en  = 1'b1;
//         PREADY = 1'b1;
//         PRDATA = 32'bx;
//         case (PADDR[3:2])
//             2'd0: PRDATA = slv_reg0;
//             2'd1: PRDATA = {25'b0, slv_reg1[7:0]}; //slv_reg1;
//             //2'd2: PRDATA = slv_reg2;
//         endcase
//         state_next = WAIT;
//     end else begin
//         state_next = IDLE;
//     end
//     // if (!fsr[0]) begin
//     //     rd_en = 1'b1;  // 1클럭만 활성화
//     //     PRDATA = slv_reg1;
//     //     PREADY = 1'b1;
//     //     state_next = WAIT;  // 즉시 전환
//     // end
// end
// WAIT: begin
//     //wr_en = 1'b0;
//     rd_en = 1'b0;
//     PREADY = 1'b0;
//     state_next = IDLE;
// end
// endcase
// end
// endmodule

module uart (
    //global port
    input  logic       clk,
    input  logic       reset,
    // rx side port
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_busy,
    input  logic       rx
);

    wire br_tick;

    baudrate_gen U_BaudRate_Gen (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick)
    );


    recevier U_Receiver (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .rx     (rx)
    );

endmodule

module baudrate_gen (
    input  logic clk,
    input  logic reset,
    output logic br_tick
);


    logic [9:0] br_counter;  //clog2(100_000_000 / 9600 / 16) = 9.xx

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            br_counter <= 0;
            br_tick <= 1'b0;
        end else begin
            if (br_counter == 650) begin  // 9600 bps (100_000_000 / 9600 / 16) - 1
                br_counter <= 0;
                br_tick <= 1'b1;
            end else begin
                br_counter <= br_counter + 1;
                br_tick <= 1'b0;
            end
        end
    end

endmodule


module recevier (
    input  logic       clk,
    input  logic       reset,
    input  logic       br_tick,
    output logic [7:0] rx_data,
    output logic       rx_done,
    output logic       rx_busy,
    input  logic       rx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, WAIT_STOP = 4;
    logic [2:0] state, state_next;

    logic rx_busy_reg, rx_busy_next;
    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_counter_reg, bit_counter_next;
    logic [5:0] tick_counter_reg, tick_counter_next;
    logic [7:0] temp_data_reg, temp_data_next;

    assign rx_data = temp_data_reg;
    assign rx_done = rx_done_reg;

    assign rx_busy = rx_busy_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            rx_done_reg      <= 1'b0;
            rx_busy_reg      <= 1'b0;
            bit_counter_reg  <= 0;
            tick_counter_reg <= 0;
            temp_data_reg    <= 0;
        end else begin
            state            <= state_next;
            rx_done_reg      <= rx_done_next;
            rx_busy_reg      <= rx_busy_next;
            bit_counter_reg  <= bit_counter_next;
            tick_counter_reg <= tick_counter_next;
            temp_data_reg    <= temp_data_next;

        end
    end

    always_comb begin
        state_next        = state;
        rx_done_next      = rx_done_reg;
        rx_busy_next      = rx_busy_reg;
        bit_counter_next  = bit_counter_reg;
        tick_counter_next = tick_counter_reg;
        temp_data_next    = temp_data_reg;


        case (state)
            IDLE: begin
                rx_busy_next = 1'b1;
                rx_done_next = 1'b0;
                if (rx == 1'b0) begin
                    state_next        = START;
                    bit_counter_next  = 0;
                    tick_counter_next = 0;
                    temp_data_next    = 0;
                end
            end
            START: begin
                if (br_tick) begin
                    if (tick_counter_reg == 8) begin  //7 //8
                        state_next = DATA;
                        tick_counter_next = 0;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                rx_done_next = 1'b0;
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin  //15
                        tick_counter_next = 0;
                        temp_data_next = {rx, temp_data_reg[7:1]};
                        if (bit_counter_reg == 7) begin
                            // state_next = WAIT;
                            state_next = STOP;
                            bit_counter_next = 0;
                            // rx_done_next = 1'b1;
                        end else begin
                            bit_counter_next = bit_counter_reg + 1;
                        end
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            STOP: begin
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin  //23
                        tick_counter_next = 0;  //
                        rx_done_next = 1'b1;
                        rx_busy_next = 1'b0;
                        state_next = WAIT_STOP;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;

                    end
                end
            end
            WAIT_STOP: begin
                rx_done_next = 1'b0;
                state_next   = IDLE;
            end
        endcase
    end


endmodule




