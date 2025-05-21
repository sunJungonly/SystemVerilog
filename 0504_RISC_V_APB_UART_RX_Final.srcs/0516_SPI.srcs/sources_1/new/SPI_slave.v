`timescale 1ns / 1ps

module SPI_slave (
    input        clk,
    input        rst,
    input        SCLK,
    input        MOSI,
    input        MISO,
    input        CS,
    //fnd port
    output [3:0] com,
    output [7:0] font
);

    wire [13:0] fndData;

    spi U_SPI (
        .clk(clk),
        .rst(rst),
        .SCLK(SCLK),
        .MOSI(MOSI),
        .MISO(MISO),
        .CS(CS),
        .fndData(fndData)
    );

    fndController U_FND (
        .clk(clk),
        .rst(rst),
        .fndData(fndData),
        .fndCom(com),
        .fndFont(font)
    );

endmodule

module spi (
    input         clk,
    input         rst,
    input         SCLK,
    input         MOSI,
    input         MISO,
    input         CS,
    output [13:0] fndData
);


    localparam IDLE = 0, L_BYTE = 1, H_BYTE = 2;
    reg [2:0] state, state_next;

    reg [1:0] sclk_sync;
    reg mosi_sampled;
    wire sclk_rising = (!sclk_sync[1] && sclk_sync[0]);
    
    reg [3:0] bit_counter_next, bit_counter;
    reg [15:0] temp_data_reg, temp_data_next;

    assign fndData = temp_data_reg[13:0];

    always @(posedge clk) begin 
        sclk_sync <= {sclk_sync[0], SCLK}; 
         mosi_sampled <= MOSI;
    end

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            temp_data_reg <= 0;
            bit_counter   <= 0;
        end else begin
            state         <= state_next;
            temp_data_reg <= temp_data_next;
            bit_counter   <= bit_counter_next;
        end
    end

    always @(*) begin
        state_next       = state;
        temp_data_next   = temp_data_reg;
        bit_counter_next = bit_counter;
        case (state)
            IDLE: begin
                temp_data_next = 13'h0;
                bit_counter_next = 0;
                if (!CS) begin
                    state_next = L_BYTE;
                end
            end
            L_BYTE: begin
                if (!CS && sclk_rising) begin
                    // Master와 같이 Lsb부터 저장
                    if (bit_counter == 8) begin
                        state_next = H_BYTE;
                        bit_counter_next = 0;
                    end else begin
                        temp_data_next[7:0] = {temp_data_reg[6:0], MOSI};
                        // temp_data_next[7:0] = {temp_data_reg[6:0], mosi_sampled};
                        // temp_data_next[8:0] = {temp_data_reg[7:0], mosi_sampled};
                        bit_counter_next = bit_counter + 1;
                        state_next = L_BYTE; 
                    end
                end 
                // else begin
                //     state_next = IDLE;
                // end
            end
            H_BYTE: begin
                if (!CS && sclk_rising) begin
                    // Master와 같이 Lsb부터 저장
                    // bit_counter_next = 0;
                    if (bit_counter == 8) begin
                        state_next = IDLE;
                        bit_counter_next = 0;
                    end else begin
                        temp_data_next[15:8] = {temp_data_reg[14:8], MOSI};
                        // temp_data_next[15:8] = {temp_data_reg[15:8], mosi_sampled};
                        bit_counter_next = bit_counter + 1;
                        state_next = H_BYTE; 
                    end
                end 
                // else begin
                //     state_next = IDLE; 
                // end
            end
        endcase
    end
endmodule
