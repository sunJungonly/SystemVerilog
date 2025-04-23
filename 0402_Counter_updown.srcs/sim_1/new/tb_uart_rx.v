`timescale 1ns / 1ps

module tb_uart_rx();

// 신호 선언
reg clk;
reg rst;
reg rx;
reg [7:0] tx_data;
reg tx_start;
wire [7:0] rx_data;
wire rx_done;
wire tx;
wire tx_done;
wire tx_busy;

// UUT 인스턴스화
Uart dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx(tx),
    .tx_done(tx_done),
    .tx_busy(tx_busy)
);



always #5 clk = ~clk;

initial begin
    // 초기화
    clk = 0;
    rst = 1;
    rx = 1;  // IDLE 상태
    #10;
    rst = 0;
    #10;


    send_data(8'h72);//"r"
    #100000;
end

task send_data(input [7:0] data);
    integer i;
    begin
        $display("Sending data: %h", data);

        // Start bit (Low)
        rx = 0;
        #(10 * 10417);  // Baud rate에 따른 시간 지연 (9600bps 기준)

        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];
            #(10 * 10417); // 각 비트 전송 시간 지연
        end

        // Stop bit (High)
        rx = 1;
        #(10 * 10417);  // 정지 비트 시간 지연

        $display("Data sent: %h", data);
    end
endtask              
  



endmodule
