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
    //    output logic        TX
);
  
    logic full, empty, rx_done, rx_busy, wr_en, rd_en;  //, tx_done, fifo_tx_empty;
    logic [7:0] rx_data, fifo_rdata, fifo_tx_rdata;

    APB_SlaveIntf_UART U_APB_Intf (
        .*,
        // internal signals
        //.wr_en(wr_en),
        .rd_en(rd_en),
        .fsr  ({rx_busy, full, empty}),
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

    // fifo U_FIFO_TX (
    //     .clk(PCLK),
    //     .reset(PRESET),
    //     // write side
    //     .wdata(PRDATA),
    //     .wr_en(PREADY), 
    //     .full(wr_en),
    //     // read side
    //     .rdata(fifo_tx_rdata),
    //     .rd_en(tx_done),
    //     .empty(fifo_tx_empty)
    // ); 

    uart U_UART (
        //global port
        .clk(PCLK),
        .reset(PRESET),
        // rx side port
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx(RX)
        //,
        // //tx side port
        // .tx_data(fifo_tx_rdata),
        // .tx_start(fifo_tx_empty),
        // .tx_busy(tx_busy),
        // .tx_done(tx_done),
        // .tx(TX)
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
   
    logic [31:0] slv_reg0, slv_reg1; //, slv_reg2;  //, slv_reg3;

    assign slv_reg0[31:0] = {30'b0, fsr};
    //assign fwd = slv_reg1[7:0];
    assign slv_reg1[31:0] = {24'b0, frd};

    typedef enum logic [1:0] {
        IDLE,
        ACCESS
        // WRITE,
        // READ,
        // WAIT
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
        PREADY = 0;
        rd_en = 0;
        PRDATA = 32'b0;

        case (state)
            IDLE: begin
                if (PSEL && PENABLE) begin
                    state_next = ACCESS;
                end
            end
            ACCESS: begin
                state_next = IDLE;
                PREADY = 1;
                if (PWRITE) begin
                    if (!fsr[1]) begin  // FIFO가 full이 아닐 때만 쓰기
                    case (PADDR[3:2])
                        2'b00: ;
                        2'b01: ;                               
                    endcase
                    end
                end else begin
                    if (!fsr[0]) begin
                    case (PADDR[3:2])
                        2'b00: PRDATA = slv_reg0;
                        2'b01:begin 
                        PRDATA = slv_reg1;
                        rd_en = 1;
                        end
                    endcase
                    end
                end
                end
        endcase
    end
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
    //                     2'd1: ;  //slv_reg1 = PWDATA;
    //                     //2'd2: ;
    //                 endcase
    //                 state_next = WAIT;
    //             end else begin
    //                 state_next = IDLE;
    //             end
    //         end
    //         READ: begin
    //             if (!fsr[0]) begin // FIFO가 empty가 아닐 때만 읽읽기
    //                 //wr_en  = 1'b0;
    //                 rd_en  = 1'b1;
    //                 PREADY = 1'b1;
    //                 PRDATA = 32'bx;
    //                 case (PADDR[3:2])
    //                     2'd0: PRDATA = slv_reg0;
    //                     2'd1: PRDATA = slv_reg1;
    //                     //2'd2: PRDATA = slv_reg2;
    //                 endcase
    //                 state_next = WAIT;
    //             end else begin
    //                 state_next = IDLE;
    //             end
    //             // if (!fsr[0]) begin
    //             //     rd_en = 1'b1;  // 1클럭만 활성화
    //             //     PRDATA = slv_reg1;
    //             //     PREADY = 1'b1;
    //             //     state_next = WAIT;  // 즉시 전환
    //             // end
    //         end
    //         WAIT: begin
    //             //wr_en = 1'b0;
    //             rd_en = 1'b0;
    //             PREADY = 1'b0;
    //             state_next = IDLE;
    //         end
    //     endcase
    // end
endmodule

module uart (
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
    input  logic       rx
);

    wire br_tick;

    baudrate_gen U_BaudRate_Gen (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick)
    );


    receiver U_Receiver (
        .clk    (clk),
        .reset  (reset),
        .br_tick(br_tick),
        .rx_data(rx_data),
        .rx_done(rx_done),
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
            if (br_counter == (100_000_000 / 9600 / 16) - 1) begin  // 9600 bps
                br_counter <= 0;
                br_tick <= 1'b1;
            end else begin
                br_counter <= br_counter + 1;
                br_tick <= 1'b0;
            end
        end
    end

endmodule


module receiver (
    input  logic       clk,
    input  logic       reset,
    input  logic       br_tick,
    output logic [7:0] rx_data,
    output logic       rx_done,
    input  logic       rx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, WAIT_STOP = 4;
    logic [2:0] state, state_next;

    logic rx_done_reg, rx_done_next;
    logic [2:0] bit_counter_reg, bit_counter_next;
    logic [5:0] tick_counter_reg, tick_counter_next;
    logic [7:0] temp_data_reg, temp_data_next;

    assign rx_data = temp_data_reg;
    assign rx_done = rx_done_reg;


    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state            <= IDLE;
            rx_done_reg      <= 1'b0;
            bit_counter_reg  <= 0;
            tick_counter_reg <= 0;
            temp_data_reg    <= 0;
        end else begin
            state            <= state_next;
            rx_done_reg      <= rx_done_next;
            bit_counter_reg  <= bit_counter_next;
            tick_counter_reg <= tick_counter_next;
            temp_data_reg    <= temp_data_next;

        end
    end

    always_comb begin
        state_next        = state;
        rx_done_next      = rx_done_reg;
        bit_counter_next  = bit_counter_reg;
        tick_counter_next = tick_counter_reg;
        temp_data_next    = temp_data_reg;

        case (state)
            IDLE: begin
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
                            state_next = STOP;
                            bit_counter_next = 0;
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
                        state_next = WAIT_STOP;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;

                    end
                end
            end
            WAIT_STOP: begin
                rx_done_next = 1'b0;
                state_next = IDLE;
            end
        endcase
    end


endmodule

// module transmitter (
//     input            clk,
//     input            reset,
//     input      [7:0] tx_data,
//     input            tx_start,
//     input            br_tick,
//     output           tx_busy,
//     output           tx_done,
//     output reg       tx
// );

//     localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

//     //latch 안생기게 하기 위한 reg
//     reg [1:0] state, state_next;
//     reg [7:0] temp_data_reg, temp_data_next;
//     reg [2:0] bit_counter_reg, bit_counter_next;
//     reg [3:0] tick_counter_reg, tick_counter_next;
//     reg tx_busy_reg, tx_busy_next, tx_done_reg, tx_done_next;

//     assign tx_busy = tx_busy_reg;
//     assign tx_done = tx_done_reg;

//     always @(posedge clk, posedge reset) begin
//         if (reset) begin
//             state            <= IDLE;
//             temp_data_reg    <= 0;
//             bit_counter_reg  <= 0;
//             tick_counter_reg <= 0;
//             tx_busy_reg      <= 1'b0;
//             tx_done_reg      <= 1'b0;


//         end else begin
//             state            <= state_next;
//             temp_data_reg    <= temp_data_next;
//             bit_counter_reg  <= bit_counter_next;
//             tick_counter_reg <= tick_counter_next;
//             tx_busy_reg      <= tx_busy_next;
//             tx_done_reg      <= tx_done_next;

//         end
//     end

//     always @(*) begin
//         state_next        = state;
//         temp_data_next    = temp_data_reg;
//         bit_counter_next  = bit_counter_reg;
//         tick_counter_next = tick_counter_reg;
//         tx_busy_next      = tx_busy_reg;
//         tx_done_next      = tx_done_reg;

//         case (state)
//             IDLE: begin
//                 tx           = 1'b1;
//                 tx_busy_next = 1'b0;
//                 tx_done_next = 1'b0;
//                 if (tx_start) begin
//                     state_next     = START;
//                     temp_data_next = tx_data;
//                     tx_busy_next   = 1'b1;
//                 end
//             end
//             START: begin
//                 tx = 1'b0;
//                 if (br_tick) begin
//                     if (tick_counter_reg == 15) begin
//                         state_next = DATA;
//                         tick_counter_next = 0;
//                         bit_counter_next = 0;
//                     end else begin
//                         tick_counter_next = tick_counter_reg + 1;
//                     end
//                 end
//             end
//             DATA: begin
//                 tx = temp_data_reg[0];
//                 if (br_tick) begin
//                     if (tick_counter_reg == 15) begin
//                         tick_counter_next = 0;
//                         if (bit_counter_reg == 7) begin
//                             state_next = STOP;
//                         end else begin
//                             bit_counter_next = bit_counter_reg + 1;
//                             temp_data_next = {
//                                 1'b0, temp_data_reg[7:1]
//                             };  // shift register 사용
//                         end
//                     end else begin
//                         tick_counter_next = tick_counter_reg + 1;
//                     end
//                 end
//             end
//             STOP: begin
//                 tx = 1'b1;
//                 if (br_tick) begin
//                     if (tick_counter_reg == 15) begin
//                         state_next        = IDLE;
//                         tick_counter_next = 0;
//                         tx_done_next      = 1'b1;
//                     end else begin
//                         tick_counter_next = tick_counter_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end
// endmodule

// `timescale 1ns / 1ps

// module UART_Periph (
//     // global signal
//     input  logic        PCLK,
//     input  logic        PRESET,
//     // APB Interface Signals
//     input  logic [ 3:0] PADDR,
//     input  logic [31:0] PWDATA,
//     input  logic        PWRITE,
//     input  logic        PENABLE,
//     input  logic        PSEL,
//     output logic [31:0] PRDATA,
//     output logic        PREADY,
//     // internal signals
//     output logic        tx,
//     input  logic        rx
// );
//     logic wr_en;
//     logic rd_en;
//     logic tx_empty;
//     logic rx_empty;
//     logic tx_full;
//     logic rx_full;
//     logic [7:0] fwd;
//     logic [7:0] frd;
//     logic tx_done;
//     logic [7:0] tx_data_in;
//     logic rx_done;
//     logic [7:0] rx_data;
//     logic btn_start;
//     logic tx_rd_en;

//     assign btn_start = ~tx_empty && ~tx_done;

//     always_ff @( posedge PCLK ) begin
//         tx_rd_en <= btn_start & ~tx_rd_en;
//     end

//     fifo U_FIFO_TX_IP (
//         .clk  (PCLK),
//         .reset(PRESET),
//         .wdata(fwd),
//         .wr_en(wr_en),
//         .full (tx_full),
//         .rdata(tx_data_in),
//         .rd_en(tx_rd_en),
//         .empty(tx_empty)
//     );
//     fifo U_FIFO_RX_IP (
//         .clk  (PCLK),
//         .reset(PRESET),
//         .wdata(rx_data),
//         .wr_en(rx_done),
//         .full (rx_full),
//         .rdata(frd),
//         .rd_en(rd_en),
//         .empty(rx_empty)
//     );

//     uart U_UART_IP (
//     .PCLK(PCLK),
//     .PRESET(PRESET),
//     .*
//     );

//     APB_SlaveIntf_FIFO U_APB_SlaveIntf_UART (
//         .*,
//         .fsr({rx_empty, tx_full})
//     );
// endmodule

// module uart (
//     input PCLK,
//     input PRESET,
//     //tx
//     input btn_start,
//     input [7:0] tx_data_in,
//     output tx_done,
//     output tx,
//     //rx
//     input rx,
//     output rx_done,
//     output [7:0] rx_data
// );


//     wire w_tick;

//     uart_tx U_Uart_TX (
//         .PCLK(PCLK),
//         .PRESET(PRESET),
//         .tick(w_tick),
//         .start_trigger(btn_start),
//         .data_in(tx_data_in),
//         .o_tx_done(tx_done),
//         .o_tx(tx)
//     );

//     uart_rx U_Uart_RX (
//         .PCLK(PCLK),
//         .PRESET(PRESET),
//         .tick(w_tick),
//         .rx(rx),
//         .rx_done(rx_done),
//         .rx_data(rx_data)
//     );

//     baud_tick_gen U_Tick_Gen (
//         .PCLK(PCLK),
//         .PRESET(PRESET),
//         .baud_tick(w_tick)
//     );

// endmodule


// module uart_tx (
//     input PCLK,
//     input PRESET,
//     input tick,
//     input start_trigger,
//     input [7:0] data_in,
//     output o_tx_done,
//     output o_tx
// );


//     parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
//     reg [1:0] state, next;
//     reg tx_reg, tx_next;
//     reg [2:0] bit_count_reg, bit_count_next;
//     reg [3:0] tick_count_reg, tick_count_next;
//     reg tx_done_reg, tx_done_next;

//     assign o_tx_done = tx_done_reg;
//     assign o_tx = tx_reg;

//     reg [7:0] temp_data_reg, temp_data_next;


//     always @(posedge PCLK, posedge PRESET) begin
//         if (PRESET) begin
//             state <= IDLE;
//             tx_reg <= 1'b1;
//             tx_done_reg <= 0;
//             bit_count_reg <= 0;
//             tick_count_reg <= 0;
//             temp_data_reg <= 0;
//         end else begin
//             state <= next;
//             tx_reg <= tx_next;
//             tx_done_reg <= tx_done_next;
//             tick_count_reg <= tick_count_next;
//             bit_count_reg <= bit_count_next;
//             temp_data_reg <= temp_data_next;
//         end
//     end


//     always @(*) begin
//         next = state;
//         tx_next = tx_reg;
//         tx_done_next = tx_done_reg;
//         bit_count_next = bit_count_reg;
//         tick_count_next = tick_count_reg;
//         temp_data_next = temp_data_reg;

//         case (state)
//             IDLE: begin
//                 tx_done_next = 1'b0;
//                 tx_next = 1'b1;
//                 tick_count_next = 0;
//                 if (start_trigger) begin
//                     next = START;
//                     // start trigger 순간의 데이터를 버퍼링 하기 위함함
//                     temp_data_next = data_in;
//                 end
//             end
//             START: begin
//                 tx_done_next = 1'b1;
//                 tx_next = 1'b0;
//                 if (tick) begin
//                     if (tick_count_reg == 15) begin
//                         next = DATA;
//                         tick_count_next = 1'b0;
//                         bit_count_next = 1'b0;
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//             DATA: begin
//                 tx_next = temp_data_reg[bit_count_reg];  // UART LSB first
//                 //tx_next = data_in[bit_count_reg]; 
//                 if (tick) begin
//                     if (tick_count_reg == 15) begin
//                         tick_count_next = 1'b0;
//                         if (bit_count_reg == 3'h7) begin
//                             next = STOP;
//                         end else begin
//                             bit_count_next = bit_count_reg + 1;
//                         end
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//             STOP: begin
//                 tx_next = 1'b1;
//                 if (tick) begin
//                     if (tick_count_reg == 15) begin
//                         next = IDLE;
//                         tick_count_next = 1'b0;
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end


// endmodule

// module uart_rx (
//     input PCLK,
//     input PRESET,
//     input tick,
//     input rx,
//     output rx_done,
//     output [7:0] rx_data
// );

//     localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

//     reg [1:0] state, next;
//     reg rx_done_reg, rx_done_next;
//     reg [2:0] bit_count_reg, bit_count_next;
//     reg [4:0] tick_count_reg, tick_count_next;
//     reg [7:0] rx_data_reg, rx_data_next;

//     assign rx_done = rx_done_reg;
//     assign rx_data = rx_data_reg;

//     always @(posedge PCLK or posedge PRESET) begin
//         if (PRESET) begin
//             state <= IDLE;
//             rx_done_reg <= 0;
//             bit_count_reg <= 0;
//             tick_count_reg <= 0;
//             rx_data_reg <= 0;
//         end else begin
//             state <= next;
//             rx_done_reg <= rx_done_next;
//             bit_count_reg <= bit_count_next;
//             tick_count_reg <= tick_count_next;
//             rx_data_reg <= rx_data_next;
//         end
//     end

//     always @(*) begin
//         next = state;
//         tick_count_next = tick_count_reg;
//         bit_count_next = bit_count_reg;
//         rx_done_next = 1'b0;
//         rx_data_next = rx_data_reg;
//         case (state)
//             IDLE: begin
//                 tick_count_next = 0;
//                 bit_count_next = 0;
//                 rx_done_next = 0;
//                 if (rx == 1'b0) begin
//                     next = START;
//                 end
//             end
//             START: begin
//                 if (tick) begin
//                     if (tick_count_reg == 7) begin
//                         tick_count_next = 0;
//                         next = DATA;
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//             DATA: begin
//                 if (tick) begin
//                     if (tick_count_reg == 15) begin

//                         rx_data_next[bit_count_reg] = rx;
//                         if (bit_count_reg == 7) begin
//                             next = STOP;
//                             bit_count_next = 0;
//                             tick_count_next = 0;
//                         end else begin
//                             next = DATA;
//                             bit_count_next = bit_count_reg + 1;
//                             tick_count_next = 0;
//                         end
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//             STOP: begin
//                 if (tick) begin
//                     if (tick_count_reg == 23) begin
//                         rx_done_next = 1'b1;
//                         next = IDLE;
//                     end else begin
//                         tick_count_next = tick_count_reg + 1;
//                     end
//                 end
//             end
//         endcase
//     end

// endmodule


// module baud_tick_gen (
//     input  PCLK,
//     input  PRESET,
//     output baud_tick
// );

//     parameter BAUD_RATE = 9600;  // BAUD_RATE_19200 = 19200;
//     localparam BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16;

//     reg [$clog2(BAUD_COUNT)-1:0] count_reg, count_next;
//     reg tick_reg, tick_next;
//     assign baud_tick = tick_reg;  // output


//     always @(posedge PCLK, posedge PRESET) begin
//         if (PRESET == 1) begin
//             count_reg <= 0;
//             tick_reg  <= 0;
//         end else begin
//             count_reg <= count_next;
//             tick_reg  <= tick_next;
//         end
//     end

//     always @(*) begin
//         count_next = count_reg;
//         tick_next  = tick_reg;
//         if (count_reg == BAUD_COUNT - 1) begin
//             count_next = 0;
//             tick_next  = 1'b1;
//         end else begin
//             count_next = count_reg + 1;
//             tick_next  = 1'b0;
//         end
//     end

// endmodule

// module APB_SlaveIntf_FIFO (
//     // global signal
//     input  logic        PCLK,
//     input  logic        PRESET,
//     // APB Interface Signals
//     input  logic [ 3:0] PADDR,
//     input  logic [31:0] PWDATA,
//     input  logic        PWRITE,
//     input  logic        PENABLE,
//     input  logic        PSEL,
//     output logic [31:0] PRDATA,
//     output logic        PREADY,
//     // internal signals
//     input  logic [ 1:0] fsr,
//     output logic        wr_en,
//     output logic        rd_en,
//     output logic [ 7:0] fwd,
//     input  logic [ 7:0] frd
// );
//     localparam EMPTY = 2'b10, FULL = 2'b01;

//     logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

//     assign fwd = slv_reg0[7:0];
//     assign slv_reg1[7:0] = frd;
//     assign slv_reg2[7:0] = fsr;

//     always_comb begin
//         wr_en  = 1'b0;
//         rd_en  = 1'b0;
//         PREADY = 1'b0;
//         PRDATA = 32'bx;
//         slv_reg0 = 32'b0;
//         if (PSEL && PENABLE) begin
//             case (fsr)
//                 EMPTY: begin
//                     if (PWRITE == 1'b1) PREADY = 1'b1;
//                     else PREADY = 1'b0;
//                 end
//                 FULL: begin
//                     if (PWRITE == 1'b0) PREADY = 1'b1;
//                     else PREADY = 1'b0;
//                 end
//                 default: PREADY = 1'b1;
//             endcase
//         end
//         if (PREADY) begin
//             if (PWRITE) begin
//                 wr_en = 1'b1;
//                 case (PADDR[3:2])
//                     2'b00: slv_reg0 = PWDATA;
//                     2'b01: ;  //slv_reg1 <= PWDATA;
//                     2'b10: ;  //slv_reg2 <= PWDATA;
//                     //2'b11: slv_reg3 <= PWDATA;
//                 endcase
//             end else begin
//                 rd_en = 1'b1;
//                 case (PADDR[3:2])
//                     2'b00: PRDATA = slv_reg0;
//                     2'b01: PRDATA = {25'b0, slv_reg1[7:0]};
//                     2'b10: PRDATA = slv_reg2;
//                     //2'b11: PRDATA <= slv_reg3;
//                 endcase
//             end
//         end
//     end

// endmodule

// module fifo (
//     input logic clk,
//     input logic reset,
//     //write side
//     input logic [7:0] wdata,
//     input logic wr_en,
//     output logic full,
//     //read side
//     output logic [7:0] rdata,
//     input logic rd_en,
//     output logic empty
// );

//     logic [1:0] wr_ptr, rd_ptr;

//     fifo_ram U_FIFO_Ram (
//         .*,
//         .wAddr(wr_ptr),
//         .wr_en(wr_en & ~full),
//         .rAddr(rd_ptr)
//     );
//     fifo_ControlUnit U_FIFO_ControlUnit (.*);
// endmodule

// module fifo_ram (
//     input              clk,
//     input  logic [1:0] wAddr,
//     input  logic [7:0] wdata,
//     input  logic       wr_en,
//     input  logic [1:0] rAddr,
//     output logic [7:0] rdata
// );
//     logic [7:0] mem[0:2**2-1];

//     always_ff @(posedge clk) begin
//         if (wr_en) mem[wAddr] <= wdata;
//     end

//     assign rdata = mem[rAddr];
// endmodule

// module fifo_ControlUnit (
//     input logic clk,
//     input logic reset,
//     //write side
//     output logic [1:0] wr_ptr,
//     input logic wr_en,
//     output logic full,
//     //read side
//     output logic [1:0] rd_ptr,
//     input logic rd_en,
//     output logic empty
// );


//     localparam READ = 2'b01, WRITE = 2'b10, READ_WRITE = 2'b11;
//     logic [1:0] wr_ptr_reg, wr_ptr_next, rd_ptr_reg, rd_ptr_next;
//     logic empty_reg, empty_next, full_reg, full_next;
//     logic [1:0] fifo_state;
//     assign fifo_state = {wr_en, rd_en};
//     assign wr_ptr = wr_ptr_reg;
//     assign rd_ptr = rd_ptr_reg;
//     assign full = full_reg;
//     assign empty = empty_reg;

//     always_ff @(posedge clk, posedge reset) begin
//         if (reset) begin
//             wr_ptr_reg <= 0;
//             rd_ptr_reg <= 0;
//             full_reg   <= 1'b0;
//             empty_reg  <= 1'b1;
//         end else begin
//             wr_ptr_reg <= wr_ptr_next;
//             rd_ptr_reg <= rd_ptr_next;
//             full_reg   <= full_next;
//             empty_reg  <= empty_next;
//         end
//     end

//     always_comb begin : fifo_comb
//         wr_ptr_next = wr_ptr_reg;
//         rd_ptr_next = rd_ptr_reg;
//         full_next   = full_reg;
//         empty_next  = empty_reg;
//         case (fifo_state)
//             READ: begin
//                 if (empty_reg == 1'b0) begin
//                     full_next   = 1'b0;
//                     rd_ptr_next = rd_ptr_next + 1;
//                     if (rd_ptr_next == wr_ptr_reg) begin
//                         empty_next = 1'b1;
//                     end
//                 end
//             end
//             WRITE: begin
//                 if (full_reg == 1'b0) begin
//                     empty_next  = 1'b0;
//                     wr_ptr_next = wr_ptr_next + 1;
//                     if (wr_ptr_next == rd_ptr_reg) begin
//                         full_next = 1'b1;
//                     end
//                 end
//             end
//             READ_WRITE: begin
//                 if (empty_reg == 1'b1) begin
//                     wr_ptr_next = wr_ptr_reg + 1;
//                     empty_next  = 1'b0;
//                 end else if (full_reg == 1'b1) begin
//                     rd_ptr_next = rd_ptr_reg + 1;
//                     full_next   = 1'b0;
//                 end else begin
//                     wr_ptr_next = wr_ptr_reg + 1;
//                     rd_ptr_next = rd_ptr_reg + 1;
//                 end
//             end
//         endcase
//     end
// endmodule