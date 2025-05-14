`timescale 1ns / 1ps

module checksum (
    input logic [39:0] data_in,
    output logic led
);

    wire [7:0] tem_int, tem_frac, hum_int, hum_frac, check_sum;
    wire [7:0] sum;

    assign tem_int = data_in[39:32];
    assign tem_frac = data_in[31:24];
    assign hum_int = data_in[23:16];
    assign hum_frac = data_in[15:8];
    assign check_sum = data_in[7:0];

    assign sum = tem_int + tem_frac + hum_int + hum_frac;

    always @(*) begin
        if (sum == check_sum) begin
            led = 0;
        end else begin
            led = 1;
        end
    end
endmodule
