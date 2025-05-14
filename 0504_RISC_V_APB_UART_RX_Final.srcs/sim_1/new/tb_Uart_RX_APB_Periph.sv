`timescale 1ns / 1ps

class transaction;
    // APB Interface Signals

    rand logic [ 3:0] PADDR;
    rand logic [31:0] PWDATA;
    rand logic        PWRITE;
    rand logic        PENABLE;
    rand logic        PSEL;
    logic      [31:0] PRDATA;  //dut out data

    logic             PREADY;  //dut out data
    rand logic        RX;
    logic      [ 7:0] rx_data;
    // outport signals
    bit        [ 1:0] fsr;
    bit        [ 7:0] frd;

    constraint c_paddr {
        PADDR dist {
            4'h0 := 10,
            4'h4 := 50
        };
    }
    //constraint c_wdata {PWDATA < 10;}
    constraint c_pwrite {
        if(PWRITE)
        PADDR == 4'h0;
        else
        PADDR == 4'h4;
    }
    

    constraint c_paddr_0 {
        if (PADDR == 0)
        PWDATA inside {3'b111, 3'b101};
        // else
        // if (PADDR == 4)
        // PWDATA < 10;
    }

    task display(string name);
        $display(
            "[%s] PADDR = %h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, RX=%h, fsr=%b, frd=%h",
            name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, RX,
            fsr, frd);
    endtask  //

endclass  //transaction


interface APB_Slave_Interface;
    logic        PCLK;
    logic        PRESET;
    // APB Interface Signals

    logic [ 3:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PENABLE;
    logic        PSEL;
    logic [31:0] PRDATA;  //dut out data
    logic        PREADY;  //dut out data
    // outport signals
    logic        RX;

    time         bit_time = 104166ns;  // 9600 baud 기준


    task send_uart_byte(input [7:0] data);
        int i;
        RX = 1'b1;  // idle

        #bit_time;
        RX = 1'b0;  // start bit

        #bit_time;

        for (i = 0; i < 8; i++) begin
            RX = data[i];
            #bit_time;
        end

        RX = 1'b1;  // stop bit

        #bit_time;
    endtask

endinterface  //APB_Slave_Interface


class generator;
    mailbox #(transaction) Gen2Drv_mbox;
    event gen_next_event;

    function new(mailbox#(transaction) Gen2Drv_mbox, event gen_next_event);
        this.Gen2Drv_mbox   = Gen2Drv_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run(int repeat_counter);
        transaction rx_tr;
        repeat (repeat_counter) begin
            rx_tr = new();  //make instance

            if (!rx_tr.randomize()) $error("Randomization fail!");
            rx_tr.display("GEN");
            Gen2Drv_mbox.put(rx_tr);
            #10;
            @(gen_next_event);  //wait an event from driver

        end
    endtask
endclass  //generator


class driver;
    virtual APB_Slave_Interface rx_intf;
    mailbox #(transaction) Gen2Drv_mbox;
    transaction rx_tr;

    function new(virtual APB_Slave_Interface rx_intf,
                 mailbox#(transaction) Gen2Drv_mbox);
        this.rx_intf = rx_intf;
        this.Gen2Drv_mbox = Gen2Drv_mbox;
    endfunction

    task run();
        forever begin
            Gen2Drv_mbox.get(rx_tr);
            rx_tr.display("DRV");
            //SETUP

            @(posedge rx_intf.PCLK);
            rx_intf.PADDR   <= rx_tr.PADDR;
            rx_intf.PWDATA  <= rx_tr.PWDATA;
            rx_intf.PWRITE  <= rx_tr.PWRITE;
            rx_intf.PENABLE <= 1'b0;
            rx_intf.PSEL    <= 1'b1;
            //ACCESS

            @(posedge rx_intf.PCLK);
            rx_intf.PADDR   <= rx_tr.PADDR;
            rx_intf.PWDATA  <= rx_tr.PWDATA;
            rx_intf.PWRITE  <= rx_tr.PWRITE;
            rx_intf.PENABLE <= 1'b1;
            rx_intf.PSEL    <= 1'b1;

            wait (rx_intf.PREADY == 1'b1);
            rx_intf.PSEL <= 1'b0;     // 추가
            rx_intf.PENABLE <= 1'b0;  // 추가
            @(posedge rx_intf.PCLK);  // 안정성을 위한 추가 클럭 사이클
            
        end
    endtask

endclass  //driver


class monitor;
    mailbox #(transaction) Mon2SCB_mbox;
    virtual APB_Slave_Interface rx_intf;
    transaction rx_tr;

    function new(virtual APB_Slave_Interface rx_intf,
                 mailbox#(transaction) Mon2SCB_mbox);
        this.rx_intf = rx_intf;
        this.Mon2SCB_mbox = Mon2SCB_mbox;
    endfunction

    task run();
        forever begin
            rx_tr = new();
            @(posedge rx_intf.PCLK);  // 클럭 에지에서 즉시 샘플링

            wait (rx_intf.PREADY == 1'b1);
            #1;
            rx_tr.PADDR   = rx_intf.PADDR;
            rx_tr.PWDATA  = rx_intf.PWDATA;
            rx_tr.PWRITE  = rx_intf.PWRITE;
            rx_tr.PENABLE = rx_intf.PENABLE;
            rx_tr.PSEL    = rx_intf.PSEL;
            rx_tr.PRDATA  = rx_intf.PRDATA;
            rx_tr.PREADY  = rx_intf.PREADY;
            rx_tr.RX      = rx_intf.RX;
            // rx_tr.rd_en = rx_intf.rd_en;

            // rx_tr.fsr   = rx_intf.fsr  ;

            // rx_tr.frd   = rx_intf.frd  ;

            rx_tr.display("MON");
            Mon2SCB_mbox.put(rx_tr);
            @(posedge rx_intf.PCLK);

        end
    endtask
endclass  //monitor


class scoreboard;
    mailbox #(transaction) Mon2SCB_mbox;
    transaction rx_tr;
    event gen_next_event;

    //reference model

    logic [31:0] refRxReg[0:1];  // 0: fsr (2-bit), 1: frd (8-bit)

    logic [1:0] refFsr;
    logic [7:0] refFrd;

    function new(mailbox#(transaction) Mon2SCB_mbox, event gen_next_event);
        this.Mon2SCB_mbox   = Mon2SCB_mbox;
        this.gen_next_event = gen_next_event;

        for (int i = 0; i < 2; i++) begin
            refRxReg[i] = 0;
        end
        refFsr = 2'b00;
        refFrd = 8'h00;
    endfunction

    int fifo_cnt = 0;

    task run();
        forever begin
            Mon2SCB_mbox.get(rx_tr);
            rx_tr.display("SCB");

            // Read 동작 시 FIFO 카운트 감소
            if (rx_tr.PWRITE == 0 && rx_tr.PADDR[3:2] == 2'd1) begin
                fifo_cnt = (fifo_cnt > 0) ? fifo_cnt - 1 : fifo_cnt; // Underflow 방지
            end

            // FIFO 상태 갱신 (refRxReg[0] 사용 안 함)
            refFsr = (fifo_cnt == 0) ? 2'b01 :  // empty
            (fifo_cnt >= 8) ? 2'b10 :  // full
            2'b00;  // normal

            // Write 동작 (FSR은 Read-Only로 가정)
            if (rx_tr.PWRITE) begin
                if (rx_tr.PADDR[3:2] != 2'd0) begin  // FSR(0x0) 쓰기 금지
                    refRxReg[rx_tr.PADDR[3:2]] = rx_tr.PWDATA;
                end
            end else begin  // Read 모드
                case (rx_tr.PADDR[3:2])
                    2'd0: begin  // FSR
                        if (rx_tr.PRDATA[1:0] != refFsr)
                            $display("[SCB FAIL] FSR mismatch");
                        else $display("[SCB PASS] FSR matched");
                    end
                    2'd1: begin  // FRD
                        if (rx_tr.PRDATA[7:0] != refRxReg[1][7:0])
                            $display("[SCB FAIL] FRD mismatch");
                        else $display("[SCB PASS] FRD matched");
                    end
                    default: $display("[SCB WARN] Invalid address");
                endcase
            end
            ->gen_next_event;
        end
    endtask

endclass  //scoreboard


class envirnment;
    mailbox #(transaction) Gen2Drv_mbox;
    mailbox #(transaction) Mon2SCB_mbox;

    generator              rx_gen;
    driver                 rx_drv;
    monitor                rx_mon;
    scoreboard             rx_scb;

    event                  gen_next_event;

    function new(virtual APB_Slave_Interface rx_intf);
        this.Gen2Drv_mbox = new();
        this.Mon2SCB_mbox = new();
        this.rx_gen       = new(Gen2Drv_mbox, gen_next_event);
        this.rx_drv       = new(rx_intf, Gen2Drv_mbox);
        this.rx_mon       = new(rx_intf, Mon2SCB_mbox);
        this.rx_scb       = new(Mon2SCB_mbox, gen_next_event);
    endfunction

    task run(int count);
        fork
            rx_gen.run(count);
            rx_drv.run();
            rx_mon.run();
            rx_scb.run();
        join_any
        ;
    endtask
endclass  //envirnment


module tb_Uart_RX_APB_Periph ();

    // logic clk, rst;
    logic [31:0] rd_data;

    // logic [7:0] refFrd;
    // logic [1:0] refFsr;
    envirnment rx_env;
    APB_Slave_Interface rx_intf ();


    initial rx_intf.PCLK = 0;

    always #5 rx_intf.PCLK = ~rx_intf.PCLK;

    Uart_RX_Periph dut (
        // global signal

        .PCLK  (rx_intf.PCLK),
        .PRESET(rx_intf.PRESET),
        // APB Interface Signals

        .PADDR  (rx_intf.PADDR),
        .PWDATA (rx_intf.PWDATA),
        .PWRITE (rx_intf.PWRITE),
        .PENABLE(rx_intf.PENABLE),
        .PSEL   (rx_intf.PSEL),
        .PRDATA (rx_intf.PRDATA),
        .PREADY (rx_intf.PREADY),
        .rx     (rx_intf.RX)
    );

    task write_APB_data(input logic [3:0] addr, input logic [31:0] data_in);
        begin
            // SETUP 단계
            rx_intf.PSEL    = 1;
            rx_intf.PENABLE = 0;
            rx_intf.PADDR   = addr;
            rx_intf.PWRITE  = 1;
            rx_intf.PWDATA  = data_in;
            @(posedge rx_intf.PCLK);

            // ACCESS 단계
            rx_intf.PENABLE = 1;
            @(posedge rx_intf.PCLK);

            // wait(PREADY) 단계
            wait (rx_intf.PREADY == 1);

            // RESET 단계
            rx_intf.PSEL    = 0;
            rx_intf.PENABLE = 0;
            @(posedge rx_intf.PCLK);
        end
    endtask

    task read_APB_data(input logic [3:0] addr, output logic [31:0] data_out);
        begin
            // SETUP 단계
            rx_intf.PSEL    = 1;
            rx_intf.PENABLE = 0;
            rx_intf.PADDR   = addr;
            rx_intf.PWRITE  = 0;
            @(posedge rx_intf.PCLK);

            // ACCESS 단계
            rx_intf.PENABLE = 1;
            @(posedge rx_intf.PCLK);

            // wait(PREADY) 단계
            wait (rx_intf.PREADY == 1);
            data_out = rx_intf.PRDATA;



            // RESET 단계
            rx_intf.PSEL    = 0;
            rx_intf.PENABLE = 0;
            @(posedge rx_intf.PCLK);
        end
    endtask

    // 100MHz 클럭(10ns 주기) 기준

    localparam CLOCK_PERIOD = 10;  // 단위: ns

    localparam TIMEOUT_CYCLES = 100_000;  // 1ms = 100,000사이클

    //2. 테스트할 UART 데이터
    byte test_data[5] = '{8'h5A, 8'h6B, 8'h7C, 8'h8D, 8'hFF};

    // initial begin
    //     rx_intf.PCLK   = 0;
    //     rx_intf.PRESET = 1;
    //     #10 rx_intf.PRESET = 0;
    //     rx_env = new(rx_intf);
    //     rx_env.run(200);
    //     #30;
    //     $display("finished!");
    //     $finish;
    // end

    initial begin
        // 1. 초기화 및 리셋

        rx_intf.PCLK = 0;
        rx_intf.PRESET = 1;
        rx_intf.RX = 1;  // UART RX 라인 기본값은 HIGH

        @(posedge rx_intf.PCLK);
        @(posedge rx_intf.PCLK);
        rx_intf.PRESET = 0;

    // 1. FIFO를 가득 채우기
    for (int i = 0; i < 5; i++) begin
        $display("[TEST] Sending UART byte: 0x%02h", test_data[i]);
        rx_intf.send_uart_byte(test_data[i]);
        repeat (1000) @(posedge rx_intf.PCLK);
    end

    // 2. full flag 확인 (fsr[1] == 1)
    read_APB_data(4'h0, rd_data);
    $display("[FSR after 5 bytes] = %02b", rd_data[1:0]);
    if (rd_data[1] != 1'b1) begin
        $error("[ERROR] FIFO not full after 4 bytes!");
        $finish;
    end

    //3. 데이터 1개 읽기 → full 플래그 꺼지는지 확인
        read_APB_data(4'h4, rd_data);
        $display("[FRD after 1st read] = 0x%02h", rd_data[7:0]);

        read_APB_data(4'h0, rd_data);
        $display("[FSR after 1st read] = %02b", rd_data[1:0]);
        if (rd_data[1] != 1'b0) begin
            $error("[ERROR] FIFO full flag did not clear after read!");
            $finish;
        end 

    // 4. 나머지 5개 데이터 읽기 및 검증
    for (int i = 1; i < 6; i++) begin
        read_APB_data(4'h4, rd_data);
        $display("[FRD] = 0x%02h", rd_data[7:0]);
        if (rd_data[7:0] !== test_data[i]) begin
            $error("[ERROR] Mismatch! Expected 0x%02h, Got: 0x%02h",
                   test_data[i], rd_data[7:0]);
            $finish;
        end
    end
    
    // 5. empty 플래그 확인 (fsr[0] == 1)
    read_APB_data(4'h0, rd_data);
    $display("[FSR final] = %02b", rd_data[1:0]);
    @(posedge rx_intf.PCLK);
    if (rd_data[0] != 1'b1) begin
        $error("[ERROR] FIFO not empty after all reads!");
        $finish;
    end

    $display("\n[TEST] Full/Empty test completed successfully!");
    end

endmodule
