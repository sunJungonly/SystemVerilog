`timescale 1ns / 1ps

module tb_mux();

    reg btn_sw_m;
    reg [16:0] x_st;
    reg [13:0] count;
    wire [18:0] y;

    mux_2x1_sw_m dut (
    .btn_sw_m(btn_sw_m),
    .x_st(x_st),
    .count(count),
    .y(y)
    );

 initial begin
        btn_sw_m = 0;
        x_st = 17'b0;
        count = 14'b0;
    
            // 첫 번째 테스트 케이스
        #10 btn_sw_m = 1; x_st = 17'b10101010101010101; count = 14'b11111111111111;
        #100;
        // 두 번째 테스트 케이스
        #10 btn_sw_m = 0; x_st = 17'b11111111111111111; count = 14'b00000000000000;

        // 세 번째 테스트 케이스
        #10 btn_sw_m = 1; x_st = 17'b00000000000000001; count = 14'b10101010101010;
        $stop;
 end

endmodule
