`timescale 1ns / 1ps

module top_counter_up_down (
    input clk,
    input rst,
    input mode,
    output [3:0] fndCom,
    output [7:0] fndFont
);

    wire [13:0] fndData;

    counter_up_down U_Counter (
    .clk(clk),
    .rst(rst),
    .mode(mode),
    .count(fndData)
    );


    fndController U_FndController(
    .clk(clk),
    .rst(rst),
    .fndData(fndData),
    .fndCom(fndCom),
    .fndFont(fndFont)
    );
endmodule


module counter_up_down(
    input clk,
    input rst,
    input mode,
    output [13:0] count
    );

    wire tick;

    clk_div_10hz U_Clk_Div_10Hz(
    .clk(clk),
    .rst(rst),
    .tick(tick)
    );

    counter U_Counter_Up_Down (
    .clk(clk),
    .rst(rst),
    .tick(tick),
    .mode(mode),
    .count(count)
    );
endmodule

module counter (
    input clk,
    input rst,
    input tick,
    input mode,
    output [13:0] count
);
    
    reg [$clog2(10000) - 1: 0] counter;

    assign count = counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter <= 0;
        end
        else begin
            if (mode == 1'b0) begin
                if(tick) begin
                    if (counter == 9999) begin
                        counter <= 0;
                    end
                    else begin
                        counter <= counter + 1;
                    end
                end
            end else begin
                if (tick) begin
                    if (counter == 0) begin
                        counter <= 9999;
                    end
                    else begin
                        counter <= counter - 1;
                    end
                end
            end    
        end
    end

endmodule

module clk_div_10hz (
    input wire clk,
    input wire rst,
    output reg tick
);
    
    reg [$clog2(10_000_000) - 1:0] div_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            div_counter <= 0;
            tick <= 1'b0;
        end
        else begin
            if (div_counter == 10_000_000 - 1) begin
                div_counter <= 0;
                tick <= 1'b1;
            end
            else begin
                div_counter <= div_counter + 1;
                tick <= 1'b0;
            end
        end
    end
endmodule