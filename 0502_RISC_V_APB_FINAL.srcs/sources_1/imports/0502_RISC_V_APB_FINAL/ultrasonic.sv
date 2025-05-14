`timescale 1ns / 1ps

module ultrasonic_sensor (
    input  logic        clk,
    input  logic        reset,
    input  logic       usr,      //ultrasonic start register
    input  logic        echo,     // HC-SR04 Echo Pulse 
    output logic        trig,
    output logic [11:0] udr,      //ultrasonic distance register
    output logic        done,
    output logic [ 6:0] d_state,
    output logic        error
);
    logic [11:0] raw_distance;
    logic raw_done;

    logic [ 2:0] o_state;

    ultrasonic U_ultrasonic (
        .clk     (clk),
        .reset   (reset),
        .start   (usr),           //sw 
        .echo    (echo),          // HC-SR04 Echo Pulse 
        .trig    (trig),          // 10us signal to HC-SR04
        .distance(raw_distance),  // test_distance to fnd
        .done    (raw_done),
        .o_state (o_state),
        .error    ()
    );

    decoder U_decoder(
        .x(o_state),
        .y(d_state)
    );

    median_filter_3samples u_filter (
        .clk           (clk),
        .reset         (reset),
        .new_data_ready(raw_done),
        .data_in       (raw_distance),
        .data_out      (udr)
    );
endmodule


module decoder (
    input  logic [ 2:0] x,
    output logic [6:0] y
);
    always_comb begin 
        y = 7'b1111111;
        case (x)
            3'd0: y = 7'b0000001; 
            3'd1: y = 7'b0000010; 
            3'd2: y = 7'b0000100; 
            3'd3: y = 7'b0001000; 
            3'd4: y = 7'b0010000; 
            3'd5: y = 7'b0100000; 
            3'd6: y = 7'b1000000; 
            default: y = 7'b1111111;
        endcase        
    end
endmodule


module median_filter_3samples #(parameter DATA_BITS = 12)(
    input clk,
    input reset,
    input new_data_ready,  //  done 
    input [DATA_BITS-1:0] data_in,  
    output reg [DATA_BITS-1:0] data_out
);

reg [DATA_BITS-1:0] sample_buffer_0, sample_buffer_1,sample_buffer_2;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        sample_buffer_0 <= 0;
        sample_buffer_1 <= 0;
        sample_buffer_2 <= 0;
        data_out <= 0;
    end
    else if (new_data_ready) begin
        sample_buffer_0 <= sample_buffer_1;
        sample_buffer_1 <= sample_buffer_2;
        sample_buffer_2 <= data_in;
        
        data_out <= (sample_buffer_0 < sample_buffer_1) ? 
                   ((sample_buffer_1 < sample_buffer_2) ? sample_buffer_1 : 
                   ((sample_buffer_0 < sample_buffer_2) ? sample_buffer_2 : sample_buffer_0)) : 
                   ((sample_buffer_0 < sample_buffer_2) ? sample_buffer_0 : 
                   ((sample_buffer_1 < sample_buffer_2) ? sample_buffer_2 : sample_buffer_1));
    end
end

endmodule

module ultrasonic #(
    parameter DATA_BITS = 12  //loc2(4000) =11.96
) (
    input logic clk,
    input logic reset,
    input logic start,  //start_btn 
    input logic echo,  // HC-SR04 Echo Pulse 
    output logic trig,
    output logic  [DATA_BITS-1:0] distance, // test_distance to fnd (000.0 cm format)
    output logic done,
    output logic [2:0] o_state,
    output logic error
);

    //parameter
    localparam TRIG_TIME = 10;  //10usec 
    localparam TIMEOUT = 38_000;  // 38msec 
    localparam ECHO_TIMEOUT = 30_000;  // 30msec 
    localparam IDLE_WAITTIME = 60_000;  //60msec
    localparam MIN_VALID_ECHO = 116;  //  under 2cm -> error 
    localparam MAX_VALID_ECHO = 23200;  // over 400cm -> error 

    //state
    localparam IDLE = 3'b000, TRIG = 3'b001, RECEIVE = 3'b010, COUNT = 3'b011,
     RESULT = 3'b100, IDLE_WAIT = 3'b101, ERROR = 3'b110; // ERROR 상태 추가
    logic [2:0] state, next;



    //register
    logic [$clog2(MAX_VALID_ECHO)-1:0]
        e_count, e_count_next;  //echo count (0 ~ 23.2msec) 
    logic [$clog2(IDLE_WAITTIME)-1:0] w_count, w_count_next;
    logic [$clog2(TRIG_TIME)-1:0] t_count, t_count_next;  //trig count

    logic done_reg, done_next;
    logic trig_reg, trig_next;
    logic error_reg, error_next;


    //output
    assign done = done_reg;
    assign o_state = state;
    assign trig = trig_reg;
    assign error = error_reg;


    assign distance = (error_reg) ? {DATA_BITS{1'b1}} : (e_count * 10) / (58);


    //tick_gen
    logic tick;

    us_tick_gen #(
        .FCOUNT(100)
    ) U_tick_gen (  //1usec
        .clk (clk),
        .rst (reset),
        .tick(tick)
    );

    //state update
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            trig_reg <= 0;
            e_count <= 0;
            w_count <= 0;
            t_count <= 0;
            done_reg <= 0;
            error_reg <= 0;
        end else begin
            state <= next;
            trig_reg <= trig_next;
            e_count <= e_count_next;
            w_count <= w_count_next;
            t_count <= t_count_next;
            done_reg <= done_next;
            error_reg <= error_next;
        end
    end

    //state combinational logic
    always @(*) begin
        next = state;
        trig_next = trig_reg;
        e_count_next = e_count;
        w_count_next = w_count;
        t_count_next = t_count;
        done_next = done_reg;
        error_next = error_reg;

        case (state)
            IDLE: begin
                done_next = 1'b0;
                w_count_next = 0;
                t_count_next = 0;
                error_next = 1'b0;
                if (start) begin
                    next = TRIG;
                end
            end
            TRIG: begin
                trig_next = 1'b1;
                if (t_count == TRIG_TIME - 1) begin
                    next = RECEIVE;
                    t_count_next = 0;
                end else begin
                    if (tick == 1'b1) begin
                        t_count_next = t_count + 1;
                    end
                end
            end
            RECEIVE: begin
                trig_next = 1'b0;
                if (echo) begin
                    e_count_next = 0;
                    next = COUNT;
                end else begin
                    if (w_count == TIMEOUT - 1) begin
                        next = ERROR;
                        error_next = 1'b1;
                        w_count_next = 0;
                    end else begin
                        if (tick == 1'b1) begin
                            w_count_next = w_count + 1;
                        end
                    end
                end
            end
            COUNT: begin
                if (echo == 1'b0) begin
                    if(e_count < MIN_VALID_ECHO || e_count > MAX_VALID_ECHO) begin
                        next = ERROR;
                        error_next = 1'b1;
                    end else begin
                        next = RESULT;
                    end
                end else begin
                    if (e_count >= ECHO_TIMEOUT) begin  // 
                        next = ERROR;
                        error_next = 1'b1;
                    end else if (tick == 1'b1) begin
                        next = COUNT;
                        e_count_next = e_count + 1;
                    end
                end
            end
            RESULT: begin
                if (tick == 1'b1) begin
                    done_next = 1'b1;
                    next = IDLE_WAIT;
                end
            end
            ERROR: begin
                if (tick == 1'b1) begin
                    done_next = 1'b1;
                    next = IDLE_WAIT;
                end
            end
            IDLE_WAIT: begin
                if (w_count == IDLE_WAITTIME - 1) begin
                    next = IDLE;
                    w_count_next = 0;
                end else begin
                    if (tick == 1'b1) begin
                        w_count_next = w_count + 1;
                    end
                end
            end
            default: next = IDLE;
        endcase
    end


endmodule


module us_tick_gen (
    input  logic clk,
    input  logic rst,
    output logic tick
);
    parameter FCOUNT = 100;  //1usec
    logic [$clog2(FCOUNT)-1:0] count_reg, count_next;

    logic tick_reg, tick_next;

    //output
    assign tick = tick_reg;

    //state
    always @(posedge clk, posedge rst) begin
        if (rst == 1'b1) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            count_reg <= count_next;
            tick_reg  <= tick_next;
        end
    end

    //next
    always @(*) begin
        count_next = count_reg;
        tick_next  = tick_reg;
        if (count_reg == FCOUNT - 1) begin
            count_next = 1'b0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
            tick_next  = 1'b0;
        end
    end
endmodule
