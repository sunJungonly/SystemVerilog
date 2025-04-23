`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input        rx,
    output       tx,
    output [3:0] fndCom,
    output [7:0] fndFont
);
    wire [13:0] fndData;
    wire [3:0] fndDot;
    wire en, clear, mode;
    wire [7:0] rx_data;
    wire rx_done;
    wire baud_tick;
    wire [7:0] tx_data;
    wire tx_start;


    Uart U_Uart (
    .clk(clk),
    .rst(reset),
    .rx(rx),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx(tx),
    .tx_done(tx_done),
    .tx_busy(tx_busy)
    );

    counter_up_down U_Counter (
        .clk(clk),
        .reset(reset),
        .en(en),
        .clear(clear),
        .mode (mode),
        .count(fndData),
        .dot_data(fndDot)
    );

    controlUnit U_CU(
        .clk(clk),
        .reset(reset),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .tx_done(tx_done),
        .tx_busy(tx_busy),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .en(en),
        .clear(clear),
        .mode(mode)
    );

    fndController U_FndController (
        .clk(clk),
        .reset(reset),
        .fndData(fndData),
        .fndDot(fndDot),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
endmodule

module counter_up_down (
    input         clk,
    input         reset,
    input         en,
    input         clear,
    input         mode,
    output [13:0] count,
    output [3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .en(en),
        .clear(clear)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .clear(clear),
        .count(count)
    );

    comp_dot U_Comp_Dot (
    .count(count),
    .dot_data(dot_data)
    );

endmodule

module comp_dot (
    input [13:0] count,
    output [3:0] dot_data
);
    assign dot_data = ((count % 10) < 5) ? 4'b1101 : 4'b1111;
    
endmodule

module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         clear,
    output [13:0] count
);
    reg [$clog2(10000)-1:0] counter;

    assign count = counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (clear) begin
                counter <= 0;
            end else begin
                if (mode == 1'b0) begin
                    if (tick) begin
                        if (counter == 9999) begin
                            counter <= 0;
                        end else begin
                            counter <= counter + 1;
                        end
                    end
                end else begin
                    if (tick) begin
                        if (counter == 0) begin
                            counter <= 9999;
                        end else begin
                            counter <= counter - 1;
                        end
                    end
                end
            end
        end
    end
endmodule

module clk_div_10hz (
    input  wire clk,
    input  wire reset,
    input  wire en,
    input  wire clear, 
    output reg  tick
);
    reg [$clog2(10_000_000)-1:0] div_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick <= 1'b0;
        end else begin
            if(en) begin
                if (div_counter == 10_000_000 - 1) begin
                    div_counter <= 0;
                    tick <= 1'b1;
                end else begin
                    div_counter <= div_counter + 1;
                    tick <= 1'b0;
                end
            end
            if (clear) begin
                div_counter <= 0;
                tick <= 1'b0;
            end
        end
    end
endmodule
