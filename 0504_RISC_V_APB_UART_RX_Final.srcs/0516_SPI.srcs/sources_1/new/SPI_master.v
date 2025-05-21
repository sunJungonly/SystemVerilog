`timescale 1ns / 1ps

module SPI_master (
    input         clk,
    input         rst,
    input         btn,
    input  [13:0] number,
    //slave port
    output        SCLK,
    output        MOSI,
    output        MISO,
    output        CS
);

    wire start, done;
    wire [7:0] data;

    master U_Master (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .number(number),
        .start(start),
        .data(data),
        .done(done)
    );

    spi_fsm U_SPIMaster (
        .clk(clk),
        .rst(rst),
        //master port
        .start(start),
        .tx_data(data),
        .rx_data(),
        .done(done),
        .ready(),
        //slave port
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS)
    );


endmodule

module master (
    input         clk,
    input         rst,
    input         btn,
    input  [13:0] number,
    output        start,
    output [ 7:0] data,
    input         done
);
localparam IDLE = 0, LOAD_LOW = 1, WAIT_LOW = 2, LOAD_HIGH = 3, WAIT_HIGH = 4;
    // localparam IDLE = 0, LOW_BIT = 1 , HIGH_BIT = 2;
    reg [2:0] state, state_next;
    reg start_reg, start_next;
    reg [7:0] data_reg, data_next;

    assign start = start_reg;
    assign data = data_reg;
    // assign data = (state == IDLE) ? 0 : (state == LOW_BIT) ? {number[7:0]} : {2'b0, number[13:8]};

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            start_reg <= 0;
            data_reg <= 0;
        end else begin
            state     <= state_next;
            start_reg <= start_next;
            data_reg <= data_next;
        end
    end

    always @(*) begin
        state_next = state;
        start_next = 0;
        data_next = 0;
    case (state)
        IDLE: begin
            if (btn) state_next = LOAD_LOW;
        end

        LOAD_LOW: begin
            data_next  = number[7:0];
            start_next = 1'b1;   // pulse start
            state_next = WAIT_LOW;
        end

        WAIT_LOW: begin
            if (done) state_next = LOAD_HIGH;
        end

        LOAD_HIGH: begin
            data_next  = {2'b00, number[13:8]};
            start_next = 1'b1;   // pulse start
            state_next = WAIT_HIGH;
        end

        WAIT_HIGH: begin
            if (done) state_next = IDLE;
        end
    endcase
        // case (state)
        //     IDLE: begin
        //         start_next = 1'b0;
        //         state_next = LOW_BIT;
        //         // data_next = 0;
        //     end
        //     LOW_BIT: begin
        //             data_next = {number[7:0]};
        //         if (btn) begin
        //             start_next = 1'b1;
        //         end
        //         if (done) begin
        //             state_next = HIGH_BIT;
        //         end 
        //     end
        //     HIGH_BIT: begin
        //             data_next = {2'b0, number[13:8]};
        //         if (btn) begin
        //             start_next = 1'b1;
        //         end
        //         if (done) begin
        //             state_next = IDLE;
        //         end
        //     end
        // endcase
    end
endmodule

module spi_fsm (
    input        clk,
    input        rst,
    //master port
    input        start,
    input  [7:0] tx_data,
    output [7:0] rx_data,
    output       done,
    output       ready,
    //slave port
    output       SCLK,
    output       MOSI,
    input        MISO,
    output       CS
);

    localparam IDLE = 0, CP0 = 1, CP1 = 2;

    reg [1:0] state, state_next;
    reg start_reg, start_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    // reg [7:0] rx_data_reg, rx_data_next;
    // reg SCLk_reg, SCLk_next;
    reg done_reg, done_next;
    reg CS_reg, CS_next;

    reg [2:0] bit_counter_next, bit_counter;
    reg [$clog2(50) - 1:0] sclk_counter_reg, sclk_counter_next;

    assign MOSI = temp_tx_data_reg[7];
    // assign rx_data = rx_data_reg;
    assign done = done_reg;
    assign CS   = CS_reg;

    assign SCLK = (state == CP1) ? 1 : 0;

    //clk_div_1mhz//

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= IDLE;
            start_reg <= 0;
            temp_tx_data_reg <= 0;
            done_reg <= 0;
            CS_reg <= 0;
            // SCLk_reg <= 0;
            sclk_counter_reg <=0;
            bit_counter <= 0;
        end else begin
            state            <= state_next;
            start_reg        <= start_next;
            temp_tx_data_reg <= temp_tx_data_next;
            done_reg         <= done_next;
            CS_reg           <= CS_next;
            // SCLk_reg         <= SCLk_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter <= bit_counter_next;
        end
    end

    always @(*) begin
        state_next        = state;
        start_next        = start_reg;
        temp_tx_data_next = temp_tx_data_reg;
        done_next         = done_reg;
        CS_next           = CS_reg;
        bit_counter_next = bit_counter;
        // rx_data_next      = rx_data_reg;
        // SCLk_next         = SCLk_reg;
        sclk_counter_next = sclk_counter_reg;

        case (state)
            IDLE: begin
                temp_tx_data_next = 8'h0;
                done_next         = 1'b0;
                CS_next           = 1'b1;
                if (start) begin
                    temp_tx_data_next = tx_data;
                    CS_next           = 1'b0;
                    state_next        = CP0;
                end
            end
            CP0: begin
                CS_next   = 1'b0;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;
                    state_next = CP1;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            CP1: begin
                CS_next   = 1'b0;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;
                    state_next = CP0;
                    if (bit_counter == 7) begin
                        done_next  = 1'b1;
                        state_next = IDLE;
                        bit_counter_next = 0;
                        // state_next = CP0;
                    end else begin
                        temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                        bit_counter_next       = bit_counter + 1;
                        state_next = CP0;
                    end
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end

endmodule


// module clk_div_1mhz (
//     input clk,
//     input rst,
//     output SCLK
// );
//     reg [$clog2(100) - 1:0] div_counter;

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             div_counter <= 0;
//             SCLK <= 1'b0;
//         end else begin
//             if (div_counter == 100 - 1) begin
//                 div_counter <= 0;
//                 SCLK <= 1'b1;
//             end
//         end
//         else begin
//             div_counter <= div_counter + 1;
//             SCLK <= 1'b0;
//         end
//     end    
// endmodule
