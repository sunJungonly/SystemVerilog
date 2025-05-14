`timescale 1ns / 1ps
   
module dht11_peri (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // export port
    inout logic dht_io  // dht11 sensor inout port
);  

    logic        w_tick_1us;
    logic [39:0] w_data_out;
    logic [ 3:0] mode_state_led;
    logic        checksum_led;

    // GPI
    logic [ 10:0] dcr;  // dcr[7:0] = uart_in, dcr[1] = modesel, dcr[0] = enable 
    //GPO
    logic [ 4:0] dlr;
    logic [15:0] ddr;

    logic        wr_en;
    logic        dht_done;
    logic [15:0] mode_data;
    logic [ 7:0] int_data;
    logic [ 7:0] frac_data;

    assign dlr = {checksum_led, mode_state_led};
 
    tick_1us #(
        .TICK_COUNT(100),
        .BIT_WIDTH (7)
    ) U_Tick_1us (
        .clk(PCLK),
        .reset(PRESET),
        .o_tick(w_tick_1us)
    );

    dht11_cu U_dht11_cu (
        .clk(PCLK),
        .reset(PRESET),
        .start(dcr[0]),
        .tick_1us(w_tick_1us),
        .empty_rx_b(dcr[10]),
        .data_uart_in(dcr[9:2]),
        .data_out(w_data_out),
        .led(mode_state_led),
        .dht_done(dht_done),
        .dht_io(dht_io)
    );

    checksum U_checksum (
        .data_in(w_data_out),
        .led(checksum_led)
    );
   
    always @(*) begin
        if (dcr[1]) begin
            mode_data = w_data_out[39:24];  //39:24
        end else begin
            mode_data = w_data_out[23:8];  //23:8
        end
        int_data = mode_data[15:8];
        frac_data = mode_data[7:0];
        ddr = (int_data * 100) + frac_data;
    end

    APB_SlaveIntf_DHT11 U_APB_SlaveIntf_DHT11 (
        .PCLK    (PCLK),
        .PRESET  (PRESET),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PWRITE  (PWRITE),
        .PENABLE (PENABLE),
        .PSEL    (PSEL),
        .PRDATA  (PRDATA),
        .PREADY  (PREADY),
        .dht_done(dht_done),
        .wr_en   (wr_en),
        .dcr     (dcr),       //{modesel, start}
        .dlr     (dlr),
        .ddr     (ddr)       // sensor data(temp or hum)
    );

endmodule

module APB_SlaveIntf_DHT11 (
    // global signal
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [ 3:0] PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    input  logic        dht_done,
    input  logic        wr_en,     // uart wr_en
    // export signals
    output logic [ 10:0] dcr,       //{empty_rx_b, uart_trig[7:0], modesel, start}
    input  logic [ 4:0] dlr,       // led input
    input  logic [15:0] ddr       // sensor data(temp or hum)
);
    logic [31:0] slv_reg0, slv_reg1, slv_reg2; //, slv_reg3;

    assign dcr = slv_reg0[9:0];
    assign slv_reg1[4:0] = dlr;
    // assign slv_reg2 = ddr;
    // assign slv_reg3[7:0] = dud;


    logic dht_data_valid;

    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 0;
            slv_reg2 <= 0;
            dht_data_valid <= 1'b0;
        end else begin
            if (dht_done) begin
                slv_reg0[10:0]  <= 2'b00;  // start 비트 자동 클리어
                slv_reg2[15:0] <= ddr;  // 센서 데이터 저장
                dht_data_valid <= 1'b1;  // 유효 플래그 설정
                // slv_reg3[ 7:0] <= 0;
            end

            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    PREADY <= 1'b1;
                    case (PADDR[3:2])
                        2'd0: begin
                            slv_reg0 <= PWDATA;
                            dht_data_valid <= 1'b0;  // 새 명령 시 이전 결과 무효화
                        end
                    endcase
                end else begin
                    PREADY <= 1'b0;
                    PRDATA <= 32'bx;
                    case (PADDR[3:2])
                        2'd0: begin
                            PRDATA <= slv_reg0;
                            PREADY <= 1'b1;
                        end
                        2'd1: begin
                            PRDATA <= slv_reg1;  // LED 상태
                            PREADY <= 1'b1;
                        end
                        2'd2: begin
                            if (dht_data_valid) begin
                                PRDATA <= slv_reg2; // 유효 시에만 데이터 반환
                                PREADY <= 1'b1;
                            end
                        end
                        // 2'd3: begin
                        //     PRDATA <= slv_reg3;  // uart data
                        //     PREADY <= 1'b1;
                        // end
                    endcase
                end
            end else begin
                PREADY <= 1'b0;
            end
        end
    end
endmodule
