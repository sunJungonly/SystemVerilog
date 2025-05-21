`timescale 1ns / 1ps

module SPI_Slave ();

endmodule

module SPI_Slave_Intf (
    input               clk,
    input            reset,
    // external signals
    input            SCLK,
    input            MOSI,
    output           MISO,
    input            SS,
    // internal signals
    output reg       done,
    output           write,
    output     [1:0] addr,
    output     [7:0] wdata,
    input      [7:0] rdata
);

    localparam IDLE = 0, CP0 = 1, CP1 = 2;

    reg [1:0] state, state_next;
    reg [7:0] temp_tx_data_next, temp_tx_data_reg;
    reg [7:0] temp_rx_data_next, temp_rx_data_reg;
    reg [2:0] bit_counter_next, bit_counter_reg;

    assign MISO = SS ? 1'bz : temp_tx_data_reg[7];

    // MOSI sequence
    always @(posedge SCLK) begin
        if (SS == 1'b0) begin
            temp_rx_data_reg <= {temp_rx_data_reg[6:0], MOSI};
        end
    end

    //MISO sequence
    always @(negedge SCLK) begin
        if (!SS && en) begin
            temp_tx_data_reg <= rdata;
            en <= 1'b0;
        end 
        else if (!SS) begin
            temp_tx_data_reg <= {temp_tx_data_reg[6:0], 1'b0};
        end 
        else begin
            en <= 1'b1;
        end
    end

    // always @(*) begin
    //     state_next = state;
    //     temp_tx_data_next = temp_tx_data_reg;
    //     case (state)
    //         SO_IDLE: begin
    //             if (SS == 1'b0 && rden) begin
    //                 temp_tx_data_next = rdata;
    //                 state_next = SO_DATA;
    //             end     
    //         end 
    //         SO_DATA: begin
    //             if (SS == 1'b0 && rden) begin
    //                 temp_tx_data_next = tem
    //             end
    //         end 
    //     endcase
    // end

    always @(posedge SCLK, posedge reset) begin
        if (reset) begin
            state <= IDLE;
            temp_tx_data_reg <= 0;
            temp_rx_data_reg <= 0;
            bit_counter_reg <= 0;
        end else begin
            state <= state_next;
            temp_tx_data_reg <= temp_tx_data_next;
            temp_rx_data_reg <= temp_rx_data_next;
            bit_counter_reg <= bit_counter_next;
        end
    end

    always @(*) begin
        state_next = state;
        temp_tx_data_next = temp_tx_data_reg;
        temp_rx_data_next = temp_rx_data_reg;
        bit_counter_next = bit_counter_reg;
        case (state)
            IDLE: begin
                if (SS == 1'b0) begin
                    temp_tx_data_next = rdata;
                end
            end
            CP0: begin
                if (SCLK == 1'b1) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], MOSI};
                end
            end
            CP1: begin
                if (SCLK == 1'b0) begin
                    if (bit_counter_reg == 7) begin
                        done = 1'b1;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule
