`timescale 1ns / 1ps

module uart (
    //global port
    input        clk,
    input        reset,
    // rx side port
    output [7:0] rx_data,
    output       rx_done,
    input        rx
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
        .rx     (rx)
    );

endmodule

module baudrate_gen (
    input      clk,
    input      reset,
    output reg br_tick
);


    reg [9:0] br_counter;  //clog2(100_000_000 / 9600 / 16) = 9.xx

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            br_counter <= 0;
            br_tick <= 1'b0;
        end else begin
            if (br_counter == 100_000_000 / 9600 / 16 - 1) begin  // 9600 bps
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
    input        clk,
    input        reset,
    input        br_tick,
    output [7:0] rx_data,
    output       rx_done,
    input        rx
);

    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] state, state_next;

    reg rx_done_reg, rx_done_next;
    reg [2:0] bit_counter_reg, bit_counter_next;
    reg [3:0] tick_counter_reg, tick_counter_next;
    reg [7:0] temp_data_reg, temp_data_next;

    assign rx_data = temp_data_reg;
    assign rx_done = rx_done_reg;


    always @(posedge clk, posedge reset) begin
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

    always @(*) begin
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
                    if (tick_counter_next == 7) begin
                        state_next = DATA;
                        tick_counter_next = 0;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;
                    end
                end
            end
            DATA: begin
                if (br_tick) begin
                    if (tick_counter_reg == 15) begin
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
                    if (tick_counter_reg == 15) begin
                        rx_done_next = 1'b1;
                        state_next   = IDLE;
                    end else begin
                        tick_counter_next = tick_counter_reg + 1;

                    end
                end
            end
        endcase
    end


endmodule
