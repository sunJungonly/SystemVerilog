`timescale 1ns / 1ps

module Uart (
    input clk,
    input rst,
    input rx,
    output [7:0] rx_data,
    output rx_done,
    input [7:0] tx_data,
    input tx_start,
    output tx,
    output tx_done,
    output tx_busy
);

    baud_tick_gen U_BAUD_Tick_Gen (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tick(baud_tick),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );
    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tick(baud_tick),
        .start(tx_start),
        .data_in(tx_data),
        .tx(tx),
        .tx_done(tx_done),
        .tx_busy(tx_busy)
    );

endmodule


module baud_tick_gen (
    input clk,
    input rst,
    output reg baud_tick
);
    parameter BAUD_RATE = 9600;
    parameter BAUD_COUNT = (100_000_000 / BAUD_RATE) / 16;
    reg [$clog2(BAUD_COUNT)- 1:0] count_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            baud_tick <= 0;
        end else begin
            if (count_reg == BAUD_COUNT - 1) begin
                count_reg <= 0;
                baud_tick <= 1;
            end else begin
                count_reg <= count_reg + 1;
                baud_tick <= 0;
            end
        end
    end

endmodule

module uart_rx (
    input clk,
    input rst,
    input tick,
    input rx,
    output [7:0] rx_data,
    output rx_done
);
    reg [2:0] bit_count_reg, bit_count_next;
    reg [3:0] tick_count_reg, tick_count_next;

    reg [7:0] rx_data_reg, rx_data_next;
    assign rx_data = rx_data_reg;

    reg rx_done_reg, rx_done_next;
    assign rx_done = rx_done_reg;

    reg [1:0] state, next;
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            bit_count_reg <= 0;
            tick_count_reg <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            state <= next;
            bit_count_reg <= bit_count_next;
            tick_count_reg <= tick_count_next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always @(*) begin
        next = state;
        bit_count_next = bit_count_reg;
        tick_count_next = tick_count_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;
        case (state)
            IDLE: begin
                bit_count_next = 0;
                tick_count_next = 0;
                rx_done_next = 0;
                rx_data_next = 0;
                if (rx == 0) begin
                    next = START;
                end
            end
            START: begin
                if (tick) begin
                    if (tick_count_reg == 7) begin
                        tick_count_next = 0;
                        next = DATA;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        rx_data_next[bit_count_reg] = rx;
                        if (bit_count_reg == 7) begin
                            next = STOP;
                            tick_count_next = 0;
                            bit_count_next = 0;
                        end else begin
                            next = DATA;
                            bit_count_next = bit_count_reg + 1;
                            tick_count_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            STOP: begin
                if (tick) begin
                    if (tick_count_reg == 7) begin
                        rx_done_next = 1;
                        next = IDLE;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule

module uart_tx (
    input clk,
    input rst,
    input tick,
    input start,
    input [7:0] data_in,
    output tx,
    output tx_done,
    output tx_busy
);
    // FSM 상태 정의
    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state, next;

    reg tx_reg, tx_next;
    reg tx_done_reg, tx_done_next;
    reg tx_busy_reg, tx_busy_next;

    assign tx = tx_reg;
    assign tx_done = tx_done_reg;
    assign tx_busy = tx_busy_reg;

    reg [2:0] data_count, data_count_next;  // 3비트 카운터 (0~7)
    reg [3:0] tick_count_reg, tick_count_next;
    reg [7:0] data_in_reg, data_in_next;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= IDLE;
            tx_reg         <= 1'b1;  // UART TX 초기 상태 HIGH
            tx_done_reg    <= 0;
            tx_busy_reg    <= 0;
            data_count     <= 0;
            tick_count_reg <= 0;
            data_in_reg    <= 0;
        end else begin
            state          <= next;
            tx_reg         <= tx_next;
            tx_done_reg    <= tx_done_next;
            tx_busy_reg    <= tx_busy_next;
            data_count     <= data_count_next;
            tick_count_reg <= tick_count_next;
        end
    end

    // 상태 전이 로직
    always @(*) begin
        next = state;
        tx_next = tx_reg;
        tx_done_next = tx_done_reg;
        tx_busy_next = tx_busy_reg;
        data_count_next = data_count;
        tick_count_next = tick_count_reg;
        data_in_next = data_in_reg;
        case (state)
            IDLE: begin
                tick_count_next = 0;
                data_count_next = 0;
                tx_done_next = 0;
                tx_busy_next = 0;
                tx_next = 1;
                data_in_next = 0;

                if (start) begin
                    next        = START;
                    tx_next     = 1'b0;
                    data_in_next = data_in;
                end

            end
            START: begin
                tx_busy_next = 1'b1;
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        next            = DATA;
                        data_count_next = 0;
                        tick_count_next = 0;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
            DATA: begin
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tx_next = data_in_next[data_count];  // 일단 출력
                        if (data_count == 7) begin
                            next = STOP;
                            tick_count_next = 0;
                            data_count_next = 0;
                            tx_next = 1;
                        end else begin
                            next = DATA;
                            data_count_next = data_count + 1;
                            tick_count_next = 0;
                        end
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end

            STOP: begin
                if (tick) begin
                    if (tick_count_reg == 15) begin
                        tx_next = 1;
                        next = IDLE;
                        tx_done_next = 1;
                    end else begin
                        tick_count_next = tick_count_reg + 1;
                    end
                end
            end
        endcase
    end

endmodule
