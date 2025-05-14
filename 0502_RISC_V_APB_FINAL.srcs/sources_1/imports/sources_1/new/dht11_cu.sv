`timescale 1ns / 1ps

module dht11_cu (
    input logic clk,
    input logic reset,
    input logic start,
    input logic tick_1us,
    input logic empty_rx_b,
    input logic [7:0] data_uart_in,
    output logic [39:0] data_out,
    output logic [3:0] led,
    output logic dht_done,
    inout logic dht_io
);

    parameter START_CNT = 18000, WAIT_CNT = 30, SYNC_CNT = 80, DATA_SYNC = 50,
              DATA_01 = 40, STOP_CNT = 50, TIME_OUT = 20000;

    parameter IDLE = 3'b000, START = 3'b001, WAIT = 3'b010, SYNC_LOW = 3'b011,
              SYNC_HIGH = 3'b100, DATA_START = 3'b101, DATA = 3'b110, WAIT_START = 3'b111;
    reg [2:0] state, next;
    reg io_oe_reg, io_oe_next;

    reg io_out_reg, io_out_next;
    reg led_reg, led_next;

    reg [14:0] count_usec_reg, count_usec_next;
    reg [39:0] data_reg, data_next;
    reg [5:0] bit_count_reg, bit_count_next;

    reg dht_done_reg, dht_done_next;

    // out 3stage on/off
    assign dht_io = (io_oe_reg) ? io_out_reg : 1'bz;
    assign led = {io_oe_reg, state};
    assign data_out = data_reg;
    // assign io_oe = io_oe_reg;
    assign dht_done = dht_done_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= 0;
            io_out_reg <= 1;
            count_usec_reg <= 0;
            led_reg <= 0;
            io_oe_reg <= 0;
            data_reg <= 0;
            bit_count_reg <= 0;
            dht_done_reg <= 0;
        end else begin
            state <= next;
            io_out_reg <= io_out_next;
            count_usec_reg <= count_usec_next;
            led_reg <= led_next;
            io_oe_reg <= io_oe_next;
            data_reg <= data_next;
            bit_count_reg <= bit_count_next;
            dht_done_reg <= dht_done_next;
        end
    end

    always @(*) begin
        next = state;
        io_out_next = io_out_reg;
        count_usec_next = count_usec_reg;
        led_next = led_reg;
        io_oe_next = io_oe_reg;
        data_next = data_reg;
        bit_count_next = bit_count_reg;
        dht_done_next = dht_done_reg;
        case (state)
            // FPGA out Sensor in
            IDLE: begin
                io_out_next = 1;
                io_oe_next = 1;
                count_usec_next = 0;
                bit_count_next = 0;
                dht_done_next = 0;
                if (start == 1 || (empty_rx_b && data_uart_in == "E")) begin
                    data_next = 0;
                    next = START;
                end
            end
            START: begin
                io_out_next = 0;
                if (tick_1us) begin
                    if (count_usec_reg == START_CNT - 1) begin
                        count_usec_next = 0;
                        next = WAIT;
                    end else begin
                        count_usec_next = count_usec_reg + 1;
                    end
                end
            end
            WAIT: begin
                io_out_next = 1;
                if (tick_1us) begin
                    if (count_usec_reg == WAIT_CNT - 1) begin
                        count_usec_next = 0;
                        io_out_next = 0;  //추가
                        next = SYNC_LOW;
                    end else begin
                        count_usec_next = count_usec_reg + 1;
                    end
                end
            end

            // Sensor out FPGA in
            SYNC_LOW: begin
                io_oe_next = 0;
                if (tick_1us) begin
                    if (dht_io) begin
                        next = SYNC_HIGH;
                    end
                end
            end
            SYNC_HIGH: begin
                if (tick_1us) begin
                    if (dht_io == 0) begin
                        next = DATA_START;
                    end
                end
            end
            DATA_START: begin
                if (tick_1us) begin
                    if (dht_io) begin
                        count_usec_next = 0;
                        next = DATA;
                    end

                end
            end
            DATA: begin
                if (tick_1us) begin
                    if (dht_io == 0) begin
                        if (count_usec_reg >= DATA_01) begin
                            data_next[39-bit_count_reg] = 1'b1;
                            count_usec_next = 0;
                            bit_count_next = bit_count_reg + 1;
                            if (bit_count_reg == DATA_01 - 1) begin
                                dht_done_next = 1;
                                next = WAIT_START;
                            end else begin
                                next = DATA_START;
                            end
                        end else if (count_usec_reg < DATA_01) begin
                            data_next[39-bit_count_reg] = 1'b0;
                            count_usec_next = 0;
                            bit_count_next = bit_count_reg + 1;
                            if (bit_count_reg == DATA_01 - 1) begin
                                dht_done_next = 1;
                                next = WAIT_START;
                            end else begin
                                next = DATA_START;
                            end
                        end else if (count_usec_reg == TIME_OUT - 1) begin
                            count_usec_next = 0;
                            next = WAIT_START;
                        end
                    end else begin
                        count_usec_next = count_usec_reg + 1;
                    end
                end
            end
            WAIT_START: begin
                dht_done_next = 0;
                next = IDLE;
            end
        endcase
    end
endmodule

