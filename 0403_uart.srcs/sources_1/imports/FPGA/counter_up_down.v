`timescale 1ns / 1ps

module top_counter_up_down (
    input        clk,
    input        reset,
    input        rs_btn,
    input        c_btn,
    input        sw_m_btn,
    input        ud_w_btn,
    output [3:0] fndCom,
    output [7:0] fndFont,
    output       tx,
    input        rx
);
    wire [16:0] fndData;
    wire [ 3:0] fndDot;
    wire en, clear, mode;
    wire [7:0] rx_data;
    wire       rx_done;
    wire [7:0] tx_data;
    wire       tx_start;
    wire       tx_busy;
    wire       tx_done;
    wire       o_r_btn, o_c_btn, o_sw_m_btn, o_ud_w_btn;
    wire [16:0] y;

    wire [6:0] msec;
    wire [5:0] sec;
    wire [3:0] min;
    wire [16:0] w_comb;
    wire cl;

    btn_debounce U_RS_Btn(
    .clk(clk),
    .reset(reset),
    .i_btn(rs_btn),
    .o_btn(o_r_btn)
    );
    btn_debounce U_C_Btn (
    .clk(clk),
    .reset(reset),
    .i_btn(c_btn),
    .o_btn(o_c_btn)
    );
    btn_debounce U_SW_M_Btn (
    .clk(clk),
    .reset(reset),
    .i_btn(sw_m_btn),
    .o_btn(o_sw_m_btn)
    );
    btn_debounce U_UD_M_Btn (
    .clk(clk),
    .reset(reset),
    .i_btn(ud_w_btn),
    .o_btn(o_ud_w_btn)
    );

    uart U_UART (
        //global port
        .clk(clk),
        .reset(reset),
        //tx side port
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .tx(tx),
        // rx side port
        .rx_data(rx_data),
        .rx_done(rx_done),
        .rx(rx)
    );

    control_unit U_ControlUnit (
        .clk     (clk),
        .reset   (reset),
        .ud_w_btn(o_ud_w_btn),
        .rs_btn(o_r_btn),
        .c_btn(o_c_btn),
        .sw_m_btn(o_sw_m_btn),
        //tx side port
        .tx_data (tx_data),
        .tx_start(tx_start),
        .tx_busy (tx_busy),
        .tx_done (tx_done),
        // rx side port
        .rx_data (rx_data),
        .rx_done (rx_done),
        // data path side port
        .en      (en),
        .clear   (clear),
        .mode    (mode),
        .cl      (cl)
    );

    top_stopwatch U_StopWatch(
        .clk(clk),
        .reset(reset),
        .btn_run(o_r_btn),
        .btn_clear(o_c_btn),
        .cl(cl),
        .msec(msec),
        .sec(sec),
        .min(min)
);

    combiner U_combiner(
        .msec(msec),
        .sec(sec),
        .min(min),
        .w_comb(w_comb)
    );

    counter_up_down U_Counter (
        .clk     (clk),
        .reset   (reset),
        .en      (en),
        .clear   (clear),
        .mode    (mode),
        .count   (fndData),
        .dot_data(fndDot)
    );

    mode_cu U_SW_M (
        .btn_sw_m(cl),
        .x_st(w_comb),
        .count(fndData),
        .y(y)
    );

    fndController U_FndController (
        .clk    (clk),
        .reset  (reset),
        .fndData(y),
        .fndDot (fndDot),
        .fndCom (fndCom),
        .fndFont(fndFont)
    );
endmodule

module wwire_combiner (
    input [6:0] msec,
    input [5:0] sec,
    input [5:0] min,
    output [18:0] w_comb
);
    assign w_comb = {min, sec, msec};

endmodule

//MUX 2x1
module mux_2x1_sw1 (
    input btn_sw_m,
    input [18:0] x_st,
    input [17:0] x_ud,
    output reg [36:0] y
);
    always @(*) begin
        case (btn_sw_m)
            1'b1: y = x_st; 
            1'b0: y = x_ud; 

            default: y = x_st;
        endcase
    end
    
endmodule

module wwire_splitter (
    input [18:0] w_split,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min 
);
    assign min = w_split[18:13];
    assign sec = w_split[12:7];
    assign msec = w_split [6:0];

endmodule
module combiner (
    input [6:0] msec,
    input [5:0] sec,
    input [3:0] min,
    output [13:0] w_comb
);
    assign min0 = min * 1000;
    assign sec0 = sec * 10;
    assign w_comb = {min0 + sec0 + msec/10};

endmodule

//MUX 2x1
module mode_cu (
    input btn_sw_m,

    input [16:0] x_st,
    input [13:0] count,
    output reg [16:0] y
);
    always @(*) begin
        case (btn_sw_m)
            1'b1: y = x_st; 
            1'b0: y = count; 

            default: y = count;
        endcase
    end
    
endmodule

// module wwire_splitter (
//     input [16:0] w_split,
//     output [6:0] msec,
//     output [5:0] sec,
//     output [3:0] min 
// );
//     assign min = w_split[16:13];
//     assign sec = w_split[12:7];
//     assign msec = w_split [6:0];

// endmodule

module control_unit (
    input            clk,
    input            reset,
    input            ud_w_btn,
    input            rs_btn,
    input            c_btn,
    input            sw_m_btn,
    //tx side port
    output reg [7:0] tx_data,
    output reg       tx_start,
    input            tx_busy,
    input            tx_done,
    // rx side port
    input      [7:0] rx_data,
    input            rx_done,
    output reg       en,
    output reg       clear,
    output reg       mode,
    output reg       cl
);
    localparam STOP = 0, RUN = 1, CL = 2, CLEAR = 3;
    localparam UP = 0, DOWN = 1;
    localparam IDLE = 0, ECHO = 1;
    localparam ON = 0, OFF = 1;
    reg [1:0] state, state_next;
    reg mode_state, mode_state_next;
    reg echo_state, echo_state_next;
    reg btn_state, btn_next;
    // always @(*) begin
    // mode = u_mode | btn_mode; // OR 연산을 procedural block에서 수행
    // end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= STOP;
            mode_state <= UP;
            echo_state <= IDLE;
        end else begin
            state <= state_next;
            mode_state <= mode_state_next;
            echo_state <= echo_state_next;
        end
    end

    always @(*) begin
        echo_state_next = echo_state;
        tx_data  = 0;
        tx_start = 1'b0;
        case (echo_state)
            IDLE: begin
                tx_data  = 0;
                tx_start = 1'b0;
                if (rx_done) begin
                    echo_state_next = ECHO;
                end
            end
            ECHO: begin
                if (tx_done) begin
                    echo_state_next = IDLE;
                end 
                else begin
                    tx_data  = rx_data;
                    tx_start = 1'b1;
                end
            end
        endcase
    end


    // always @(*) begin
    //     btn_next = btn_state;
    //     btn_mode = 1'b0;
    //     case (btn_state)
    //         UP: begin
    //             btn_mode = 1'b0;
    //             if (ud_w_btn == 1)
    //                 btn_next = DOWN;  
    //         end
    //         DOWN: begin
    //             btn_mode = 1'b1;
    //             if (ud_w_btn == 1)
    //                 btn_next = UP;  
    //         end
    //     endcase
    // end

    always @(*) begin
        mode_state_next = mode_state;
        mode = 1'b0;
        case (mode_state)
            UP: begin
                mode = 1'b0;
                if (ud_w_btn) begin
                    mode_state_next = DOWN;
                end
                    if (rx_done) begin
                        if (rx_data == 8'h4d || rx_data == 8'h6d)
                            mode_state_next = DOWN;  //m
                    end
            end
            DOWN: begin
                mode = 1'b1;
                if (ud_w_btn) begin
                    mode_state_next = UP;
                end
                if (rx_done) begin
                    if (rx_data == 8'h4d || rx_data == 8'h6d)
                        mode_state_next = UP;  //m
                end
            end
        endcase
    end

    always @(*) begin
        state_next = state;
        en         = 1'b0;
        clear      = 1'b0;
        cl         = 1'b0;
        case (state)
            STOP: begin
                en = 1'b0;
                clear = 1'b0;
                cl         = 1'b0;
                if (rs_btn) begin
                    state_next = RUN;
                end
                if (c_btn) begin
                    state_next = CLEAR;
                end
                if (sw_m_btn) begin
                    state_next = CL;
                end
                if (rx_done) begin
                    if (rx_data == 8'h52 || rx_data == 8'h72)
                        state_next = RUN;  //r
                    else if (rx_data == 8'h43 || rx_data == 8'h63)
                        state_next = CLEAR;
                    else if (rx_data == 8'h57 || rx_data == 8'h77) begin
                    state_next = CL; //w
                end
                end

            end
            RUN: begin
                en = 1'b1;
                clear = 1'b0;
                cl         = 1'b0;
                if (rs_btn) begin
                    state_next = STOP;
                end
                if (rx_done) begin
                    if (rx_data == 8'h53 || rx_data == 8'h73)
                        state_next = STOP;  //s
                        if (rx_data == 8'h58 || rx_data == 8'h78) begin
                            state_next = CL; //w
                        end
                end
            end
            CL: begin
                en = 1'b0;
                cl =  1'b1;
                clear = 1'b0;
                if (rx_data == 8'h53 || rx_data == 8'h73) begin
                            state_next = RUN; //w
                        end
            end
            CLEAR: begin
                en = 1'b0;
                clear = 1'b1;
                cl         = 1'b0;
                state_next = STOP;
            end
        endcase
    end
endmodule




module comp_dot (
    input  [13:0] count,
    output [ 3:0] dot_data
);
    assign dot_data = ((count % 10) < 5) ? 4'b0101 : 4'b1111;
endmodule

module counter_up_down (
    input         clk,
    input         reset,
    input         en,
    input         clear,
    input         mode,
    output [13:0] count,
    output [ 3:0] dot_data
);
    wire tick;

    clk_div_10hz U_Clk_Div_10Hz (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .en   (en),
        .clear(clear)
    );

    counter U_Counter_Up_Down (
        .clk  (clk),
        .reset(reset),
        .tick (tick),
        .mode (mode),
        .en   (en),
        .clear(clear),
        .count(count)
    );

    comp_dot U_Comp_Dot (
        .count(count),
        .dot_data(dot_data)
    );
endmodule


module counter (
    input         clk,
    input         reset,
    input         tick,
    input         mode,
    input         en,
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
                if (en) begin
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
            if (en) begin
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
