`timescale 1ns / 1ps
module top_stopwatch(
    input clk,
    input reset,
    input btn_run,
    input btn_clear,
    input cl,
    output [6:0] msec,
    output [5:0] sec,
    output [3:0] min
);

    stopwatch_cu U_stopwatch_cu(
    .clk(clk),
    .reset(reset),
    .i_btn_run(btn_run),
    .i_btn_clear(btn_clear),
    .cl(cl),
    .o_run(run),
    .o_clear(clear)
    );

    stopwatch_dp U_stopwatch_DP(
    .clk(clk),
    .reset(reset),
    .run(run),
    .clear(clear),
    .msec(msec),
    .sec(sec),
    .min(min)
    );

endmodule




module stopwatch_cu(
    input clk,
    input reset,
    input i_btn_run,
    input i_btn_clear,
    input cl,
    output reg o_run,
    output reg o_clear
    );

    // fsm 구조로 CU 설계
    parameter STOP = 2'b00, RUN = 2'b01, CLEAR = 2'b10;
    reg [1:0] state, next;

    // state register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP; // STOP
        end else begin
            state <= next;
        end
    end

    // next
    always @(*) begin
        next = state;
        if (cl) begin  
            case (state)
                STOP: begin
                    if (i_btn_run == 1) begin // 1'b1
                        next = RUN;
                    end else if (i_btn_clear == 1'b1) begin
                        next = CLEAR;
                    end // 맨 위에서 초기화 했기 때문에 else 필요 없음음
                end 
                RUN: begin
                    if (i_btn_run == 1) begin
                        next = STOP;
                    end
                end 
                CLEAR: begin
                    if (i_btn_clear == 1) begin
                        next = STOP;
                    end
                end 
            endcase
        end
    end

//출력력
    always @(*) begin
        o_run = 1'b0;
        o_clear = 1'b0; // latch 방지
        case (state)    
            STOP: begin
                o_run = 1'b0;
                o_clear = 1'b0; // 1'b0
            end

            RUN: begin
                o_run = 1'b1;
                o_clear = 1'b0;
            end

            CLEAR: begin
                o_run = 1'b0;
                o_clear = 1'b1;
            end
        endcase
    end

endmodule


module stopwatch_dp(
    input clk,
    input reset,
    input run,
    input clear,
    output [6:0] msec,
    output [5:0] sec,
    output [3:0] min
    );

    wire w_clk_100hz;
    wire w_msec_tick, w_sec_tick, w_min_tick;
    

    clk_div_100 U_CLK_Div(
        .clk(clk),
        .reset(reset),
        .run(run),
        .clear(clear),
        .o_clk(w_clk_100hz)
    );

    time_counter #(.TICK_COUNT(100), .BIT_WIDTH(7)) U_Time_Msec(
        .clk(clk),
        .reset(reset),
        .tick(w_clk_100hz),
        .clear(clear),
        .o_time(msec),
        .o_tick(w_msec_tick)
    );

    time_counter #(.TICK_COUNT(60), .BIT_WIDTH(6)) U_Time_sec(
        .clk(clk),
        .reset(reset),
        .tick(w_msec_tick),
        .clear(clear),
        .o_time(sec),
        .o_tick(w_sec_tick)
    );

    time_counter #(.TICK_COUNT(9), .BIT_WIDTH(4)) U_Time_Min(
        .clk(clk),
        .reset(reset),
        .tick(w_sec_tick),
        .clear(clear),
        .o_time(min),
        .o_tick(w_min_tick)
    );
    

endmodule


    module time_counter #(parameter TICK_COUNT = 100, BIT_WIDTH = 7) ( 
        input clk,
        input reset,
        input tick,
        input clear,
        output [BIT_WIDTH - 1 : 0]o_time, // 놓침
        output o_tick
    );
        
        reg [$clog2(TICK_COUNT)-1 : 0] count_reg, count_next; // for state
        reg tick_reg, tick_next;                              // for output
        
        assign o_time = count_reg;
        assign o_tick = tick_reg;

        always @(posedge clk, posedge reset) begin
            if (reset) begin
                count_reg <= 0;
                tick_reg <= 0;
            end else begin
                count_reg <= count_next;
                tick_reg <= tick_next;
            end
        end

        always @(*) begin
            count_next = count_reg; // 고민뚠뚠
            tick_next = 1'b0; // 0 -> 1 -> 0 2clk 걸림//output
            if (clear == 1'b1) begin
                count_next = 0;
            end 
            else if (tick == 1'b1) begin
                if (count_reg == TICK_COUNT - 1) begin
                    count_next = 0;
                    tick_next = 1'b1;
                end else begin
                    count_next = count_reg + 1;
                    tick_next = 1'b0;
                end
            end
        end

    endmodule

    module clk_div_100 (
        input clk,
        input reset,
        input run,
        input clear,
        output o_clk
        
    );
        parameter FCOUNT = 1_000_000; //100; for test 2 //10; for test
        reg [$clog2(FCOUNT) - 1 : 0] count_reg, count_next;
        reg clk_reg, clk_next; // ** 출력을 f/f으로 내보내기 위해서
        
        assign o_clk = clk_reg; // 최종 출력

        always @(posedge clk, posedge reset) begin
            if (reset) begin
                count_reg   <= 0;
                clk_reg     <= 0;
            end else begin
                count_reg <= count_next;
                clk_reg   <= clk_next;
            end           
        end
        
        always @(*) begin
            count_next  = count_reg;
            clk_next    = 1'b0;
            if (run == 1'b1) begin
                if (count_reg == (FCOUNT-1)) begin
                    count_next = 0;
                    clk_next   = 1'b1; // high 출력
                end else begin
                    count_next = count_reg + 1;
                    clk_next = 1'b0;
                end
            end else if (clear == 1) begin
                count_next <= 0;
                clk_next <= 0;
            end
        end

    endmodule


    