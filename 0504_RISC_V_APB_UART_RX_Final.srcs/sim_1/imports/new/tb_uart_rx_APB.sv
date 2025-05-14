// `timescale 1ns / 1ps

// class transaction;
//     // APB Interface Signals

//     rand logic [ 3:0] PADDR;
//     rand logic [31:0] PWDATA;
//     rand logic        PWRITE;
//     rand logic        PENABLE;
//     rand logic        PSEL;
//     logic      [31:0] PRDATA;  //dut out data
//     logic             PREADY;  //dut out data
//     rand logic [ 7:0] RX;
//     logic               RX_1bit;
//     // outport signals
//     logic      [ 1:0] fsr;
//     logic      [ 7:0] frd;

//     constraint c_paddr {
//         PADDR dist {
//             4'h0 <= 10,
//             4'h4 <= 50
//         };
//     }
//     //constraint c_wdata {PWDATA < 10;}

//     constraint c_paddr_0 {
//         if (PADDR == 0)
//         PWDATA inside {1'b0, 1'b1};
//         else
//         if (PADDR == 4) PWDATA < 8'hff;
//     }

//     task display(string name);
//         $display(
//             "[%s] PADDR = %h, PWDATA=%h, PWRITE=%h, PENABLE=%h, PSEL=%h, PRDATA=%h, PREADY=%h, RX=%h, fsr=%b, frd=%h",
//             name, PADDR, PWDATA, PWRITE, PENABLE, PSEL, PRDATA, PREADY, RX,
//             fsr, frd);
//     endtask  //

// endclass  //transaction


// interface APB_Slave_Interface;
//     logic        PCLK;
//     logic        PRESET;
//     // APB Interface Signals

//     logic [ 3:0] PADDR;
//     logic [31:0] PWDATA;
//     logic        PWRITE;
//     logic        PENABLE;
//     logic        PSEL;
//     logic [31:0] PRDATA;  //dut out data
//     logic        PREADY;  //dut out data
//     // outport signals
//     logic        RX;
//     logic      [ 1:0] fsr;
//     logic      [ 7:0] frd;


// endinterface  //APB_Slave_Interface


// class generator;
//     mailbox #(transaction) Gen2Drv_mbox;
//     mailbox #(transaction) Gen2Scb_mbox;
//     transaction rx_tr, gen_tr;

//     event gen_next_event;

//     function new(mailbox#(transaction) Gen2Drv_mbox, Gen2Scb_mbox, event gen_next_event);
//         this.Gen2Drv_mbox   = Gen2Drv_mbox;
//         this.Gen2Scb_mbox   = Gen2Scb_mbox;
//         this.gen_next_event = gen_next_event;
//     endfunction

//     task run(int repeat_counter);
//         transaction rx_tr;
//         repeat (repeat_counter) begin
//             rx_tr = new();  //make instance
//             if (!rx_tr.randomize()) $error("Randomization fail!");
//             rx_tr.display("GEN");
//             Gen2Drv_mbox.put(rx_tr);
//             Gen2Scb_mbox.put(gen_tr);
//             @(gen_next_event);  //wait an event from driver

//         end
//     endtask
    
// endclass  //generator


// class driver;
//     virtual APB_Slave_Interface rx_intf;
//     mailbox #(transaction) Gen2Drv_mbox;
//     transaction rx_tr;

//     function new(virtual APB_Slave_Interface rx_intf,
//                  mailbox#(transaction) Gen2Drv_mbox);
//         this.rx_intf = rx_intf;
//         this.Gen2Drv_mbox = Gen2Drv_mbox;
//     endfunction

//     task write();
//         //SETUP
//         @(posedge rx_intf.PCLK);
//         rx_intf.PADDR   <= rx_tr.PADDR;
//         rx_intf.PWDATA  <= rx_tr.PWDATA;
//         rx_intf.PWRITE  <= rx_tr.PWRITE;
//         rx_intf.PENABLE <= 1'b0;
//         rx_intf.PSEL    <= 1'b1;
//         rx_intf.RX      <= rx_tr.RX;

//         //ACCESS
//         @(posedge rx_intf.PCLK);
//         rx_intf.PADDR   <= rx_tr.PADDR;
//         rx_intf.PWDATA  <= rx_tr.PWDATA;
//         rx_intf.PWRITE  <= rx_tr.PWRITE;
//         rx_intf.PENABLE <= 1'b1;
//         rx_intf.PSEL    <= 1'b1;
//         rx_intf.RX    <= rx_tr.RX;

//         wait (rx_intf.PREADY == 1'b1);

//         // RESET 단계
//         rx_intf.PENABLE <= 1'b0;  // 추가
//         rx_intf.PSEL <= 1'b0;     // 추가
//         @(posedge rx_intf.PCLK);  // 안정성을 위한 추가 클럭 사이클
//     endtask  //write

//     task read();
//         //SETUP
//         @(posedge rx_intf.PCLK);
//         rx_intf.PADDR   <= rx_tr.PADDR;
//         rx_intf.PWRITE  <= 1'b0;
//         rx_intf.PENABLE <= 1'b0;
//         rx_intf.PSEL    <= 1'b1;
       

//         //ACCESS
//         @(posedge rx_intf.PCLK);
//         rx_intf.PADDR   <= rx_tr.PADDR;
//         rx_intf.PWRITE  <= 1'b0;
//         rx_intf.PENABLE <= 1'b1;
//         rx_intf.PSEL    <= 1'b1;

//         // wait(PREADY) 단계
//         wait (rx_intf.PREADY == 1'b1);
//         rx_tr.PRDATA <= rx_intf.PRDATA;
//         // rx_intf.PRDATA <= rx_tr.PRDATA;

//         // RESET 단계
//         rx_intf.PENABLE <= 1'b0;  // 추가
//         rx_intf.PSEL <= 1'b0;     // 추가
//         @(posedge rx_intf.PCLK);  // 안정성을 위한 추가 클럭 사이클
//     endtask  //writreade

//     task run();
//         forever begin
//             Gen2Drv_mbox.get(rx_tr);

//             send_uart_byte(rx_tr.RX);
//             // APB 트랜잭션 처리
//             if (rx_tr.PWRITE) write();
//             else read();
            
//             rx_tr.display("DRV");
//             // // Full/Empty 플래그 기반 분기
//             // if (rx_tr.fsr[1:0] == 2'b10) begin  // Full 상태
//             //     $display("[DRV] FIFO Full - Write Blocked");
//             // end else if (rx_tr.fsr[1:0] == 2'b01) begin  // Empty 상태
//             //     $display("[DRV] FIFO Empty - Read Blocked");
//             //     if (rx_tr.PWRITE) write();
//             // end else begin  // Read 트랜잭션
//             //     read();
//             // end

//             // rx_tr.display("DRV");

//         end
//     endtask

//     task send_uart_byte(input [7:0] data);
// // UART 프로토콜: [Idle:1][Start:0][Data:8b LSB first][Stop:1]
//     // 9600 baud = 104,166ns/bit (주파수 96MHz 기준)
//     int i;
//     // Idle 상태 유지
//     rx_intf.RX = 1'b1;
//     #104166ns;

//     // Start 비트 전송
//     rx_intf.RX = 1'b0;
//     #104166ns;

//     // 데이터 비트 전송 (LSB first)
//     for (int i=0; i<8; i++) begin
//         rx_intf.RX = data[i];  // [Search result 3]
//         #104166ns;
//     end

//     // Stop 비트 전송
//     rx_intf.RX = 1'b1;
//     #104166ns;
//     endtask

// endclass  //driver


// class monitor;
//     mailbox #(transaction) Mon2SCB_mbox;
//     virtual APB_Slave_Interface rx_intf;
//     transaction rx_tr;

//     function new(virtual APB_Slave_Interface rx_intf,
//                  mailbox#(transaction) Mon2SCB_mbox);
//         this.rx_intf = rx_intf;
//         this.Mon2SCB_mbox = Mon2SCB_mbox;
//     endfunction

//     task run();
//         forever begin
//             rx_tr = new();
//             @(posedge rx_intf.PCLK);
            
//             wait (rx_intf.PREADY == 1'b1);

//             rx_tr.PADDR = rx_intf.PADDR;
//             rx_tr.PWDATA = rx_intf.PWDATA;
//             rx_tr.PWRITE = rx_intf.PWRITE;
//             rx_tr.PENABLE = rx_intf.PENABLE;
//             rx_tr.PSEL = rx_intf.PSEL;
//             rx_tr.PRDATA = rx_intf.PRDATA;
//             rx_tr.PREADY = rx_intf.PREADY;
//             rx_tr.RX = rx_intf.RX;

//             rx_tr.display("MON");
//             Mon2SCB_mbox.put(rx_tr);


//         end
//     endtask
// endclass  //monitor


// class scoreboard;
//     mailbox #(transaction) Mon2SCB_mbox;
//     mailbox #(transaction) Gen2Scb_mbox;
//     transaction rx_tr, gen_tr;
//     event gen_next_event;

//     //reference model

//     logic [31:0] refRxReg[0:1];  // 0: fsr (2-bit), 1: frd (8-bit) 


//     function new(mailbox#(transaction) Mon2SCB_mbox, Gen2Scb_mbox, event gen_next_event);
//         this.Mon2SCB_mbox   = Mon2SCB_mbox;
//         this.Gen2Scb_mbox   = Gen2Scb_mbox;
//         this.gen_next_event = gen_next_event;

//         for (int i = 0; i < 2; i++) begin
//             refRxReg[i] = 0;
//         end
//     endfunction

    

//     task run();
//         forever begin
//             Mon2SCB_mbox.get(rx_tr);
//             Gen2Scb_mbox.get(gen_tr);
//             rx_tr.display("SCB"); 

//             // FRD 비교 (Addr 0x4)
//                     if (rx_tr.PADDR == 4'h4 && !rx_tr.PWRITE) begin
//                         if (rx_tr.PRDATA[7:0] != gen_tr.RX[7:0])  // [6]
//                             $error("FRD Mismatch! Exp:%0h Got:%0h", 
//                                 gen_tr.RX, rx_tr.PRDATA);
//                     end
                
//                 end
//         //     if (rx_tr.PADDR == 4'h4 && rx_tr.PWRITE && rx_tr.PENABLE) begin
//         //         refRxReg[1][7:0] =  gen_tr.RX[7:0];
//         //     end

//         //     if (rx_tr.PADDR == 4'h0 && !rx_tr.PWRITE && rx_tr.PENABLE) begin
//         //         refRxReg[0][1:0] =  gen_tr.PRDATA[1:0];
//         //     end
            
//         //     // // FSR 검증 (Addr=0x0)
//         //     // if (rx_tr.PADDR == 4'h0 && !rx_tr.PWRITE) begin
//         //     //     if (rx_tr.PRDATA[1:0] == refRxReg[0][1:0]) begin
//         //     //         $display("FRD PASS! Addr=0x4, Val=%0h", rx_tr.PRDATA[1:0]);
//         //     //     end
//         //     // end

//         //     // FRD 검증 (Addr=0x4)
//         //     if (rx_tr.PADDR == 4'h4 && !rx_tr.PWRITE) begin
//         //         if (rx_tr.PRDATA[7:0] == refRxReg[1][7:0]) begin
//         //             $display("FRD PASS! Addr=0x4, Val=%0h", rx_tr.PRDATA[7:0]);
//         //         end else $display("FRD FAIL! Addr=0x4, Val=%0h", rx_tr.PRDATA[7:0]);
//         //     end
//         // end
//             ->gen_next_event;  //event trigger
//     endtask

// endclass  //scoreboard


// class envirnment;
//     mailbox #(transaction) Gen2Drv_mbox;
//     mailbox #(transaction) Mon2SCB_mbox;
//     mailbox #(transaction) Gen2Scb_mbox;

//     generator              rx_gen;
//     driver                 rx_drv;
//     monitor                rx_mon;
//     scoreboard             rx_scb;

//     event                  gen_next_event;

//     function new(virtual APB_Slave_Interface rx_intf);
//         this.Gen2Drv_mbox = new();
//         this.Mon2SCB_mbox = new();
//         this.rx_gen       = new(Gen2Drv_mbox, Gen2Scb_mbox, gen_next_event);
//         this.rx_drv       = new(rx_intf, Gen2Drv_mbox);
//         this.rx_mon       = new(rx_intf, Mon2SCB_mbox);
//         this.rx_scb       = new(Mon2SCB_mbox, Gen2Scb_mbox, gen_next_event);
//     endfunction

//     task run(int count);
//         fork
//             rx_gen.run(count);
//             rx_drv.run();
//             rx_mon.run();
//             rx_scb.run();
//         join_any
//         ;
//     endtask
// endclass  //envirnment


// module tb_Uart_RX_APB_Periph ();

//     logic clk, rst;
//     logic [31:0] rd_data;

//     logic [7:0] refFrd;
//     logic [1:0] refFsr;
//     envirnment rx_env;
//     APB_Slave_Interface rx_intf ();


//     initial rx_intf.PCLK = 0;

//     always #5 rx_intf.PCLK = ~rx_intf.PCLK;

//     Uart_RX_Periph dut (
//         // global signal

//         .PCLK  (rx_intf.PCLK),
//         .PRESET(rx_intf.PRESET),
//         // APB Interface Signals
//         .PADDR  (rx_intf.PADDR),
//         .PWDATA (rx_intf.PWDATA),
//         .PWRITE (rx_intf.PWRITE),
//         .PENABLE(rx_intf.PENABLE),
//         .PSEL   (rx_intf.PSEL),
//         .PRDATA (rx_intf.PRDATA),
//         .PREADY (rx_intf.PREADY),
//         .RX     (rx_intf.RX)
//     );

//     initial begin
//         rx_intf.PCLK   = 0;
//         rx_intf.PRESET = 1;
//         #10 rx_intf.PRESET = 0;
//         rx_env = new(rx_intf);
//         rx_env.run(200);
//         #30;
//         $display("finished!");
//         $finish;
//     end

// endmodule


// // task write_APB_data(input logic [3:0] addr, input logic [31:0] data_in);
// //     begin
// //         // SETUP 단계
// //         rx_intf.PSEL    = 1;
// //         rx_intf.PENABLE = 0;
// //         rx_intf.PADDR   = addr;
// //         rx_intf.PWRITE  = 1;
// //         rx_intf.PWDATA  = data_in;
// //         @(posedge rx_intf.PCLK);

// //         // ACCESS 단계
// //         rx_intf.PENABLE = 1;
// //         @(posedge rx_intf.PCLK);

// //         // wait(PREADY) 단계
// //         wait (rx_intf.PREADY == 1);

// //         // RESET 단계
// //         rx_intf.PSEL    = 0;
// //         rx_intf.PENABLE = 0;
// //         @(posedge rx_intf.PCLK);
// //     end
// // endtask

// // task read_APB_data(input logic [3:0] addr, output logic [31:0] data_out);
// //     begin
// //         // SETUP 단계
// //         rx_intf.PSEL    = 1;
// //         rx_intf.PENABLE = 0;
// //         rx_intf.PADDR   = addr;
// //         rx_intf.PWRITE  = 0;
// //         @(posedge rx_intf.PCLK);

// //         // ACCESS 단계
// //         rx_intf.PENABLE = 1;
// //         @(posedge rx_intf.PCLK);

// //         // wait(PREADY) 단계
// //         wait (rx_intf.PREADY == 1);
// //         data_out = rx_intf.PRDATA;



// //         // RESET 단계
// //         rx_intf.PSEL    = 0;
// //         rx_intf.PENABLE = 0;
// //         @(posedge rx_intf.PCLK);
// //     end
// // endtask


// // int fifo_cnt = 0;

// // task run();
// //     forever begin
// //         Mon2SCB_mbox.get(rx_tr);
// //         rx_tr.display("SCB");

// //         // Read 동작 시 FIFO 카운트 감소
// //         if (rx_tr.PWRITE == 0 && rx_tr.PADDR[3:2] == 2'd1) begin
// //             fifo_cnt = (fifo_cnt > 0) ? fifo_cnt - 1 : fifo_cnt; // Underflow 방지
// //         end

// //         // FIFO 상태 갱신 (refRxReg[0] 사용 안 함)
// //         refFsr = (fifo_cnt == 0) ? 2'b01 :  // empty
// //         (fifo_cnt >= 8) ? 2'b10 :  // full
// //         2'b00;  // normal

// //         // Write 동작 (FSR은 Read-Only로 가정)
// //         if (rx_tr.PWRITE) begin
// //             if (rx_tr.PADDR[3:2] != 2'd0) begin  // FSR(0x0) 쓰기 금지
// //                 refRxReg[rx_tr.PADDR[3:2]] = rx_tr.PWDATA;
// //             end
// //         end else begin  // Read 모드
// //             case (rx_tr.PADDR[3:2])
// //                 2'd0: begin  // FSR
// //                     if (rx_tr.PRDATA[1:0] != refFsr)
// //                         $display("[SCB FAIL] FSR mismatch");
// //                     else $display("[SCB PASS] FSR matched");
// //                 end
// //                 2'd1: begin  // FRD
// //                     if (rx_tr.PRDATA[7:0] != refRxReg[1][7:0])
// //                         $display("[SCB FAIL] FRD mismatch");
// //                     else $display("[SCB PASS] FRD matched");
// //                 end
// //                 default: $display("[SCB WARN] Invalid address");
// //             endcase
// //         end
// //         ->gen_next_event;
// //     end
// // endtask


// //     // 100MHz 클럭(10ns 주기) 기준

// //     localparam CLOCK_PERIOD = 10;  // 단위: ns

// //     localparam TIMEOUT_CYCLES = 100_000;  // 1ms = 100,000사이클

// //     // 2. 테스트할 UART 데이터
// //     byte test_data[5] = '{8'h5A, 8'h6B, 8'h7C, 8'h8D, 8'hFF};

// //     initial begin
// //         // 1. 초기화 및 리셋

// //         rx_intf.PCLK = 0;
// //         rx_intf.PRESET = 1;
// //         rx_intf.RX = 1;  // UART RX 라인 기본값은 HIGH

// //         @(posedge rx_intf.PCLK);
// //         @(posedge rx_intf.PCLK);
// //         rx_intf.PRESET = 0;

// //     // 1. FIFO를 가득 채우기
// //     for (int i = 0; i < 5; i++) begin
// //         $display("[TEST] Sending UART byte: 0x%02h", test_data[i]);
// //         rx_intf.send_uart_byte(test_data[i]);
// //         repeat (1000) @(posedge rx_intf.PCLK);
// //     end

// //     // 2. full flag 확인 (fsr[1] == 1)
// //     read_APB_data(4'h0, rd_data);
// //     $display("[FSR after 5 bytes] = %02b", rd_data[1:0]);
// //     if (rd_data[1] != 1'b1) begin
// //         $error("[ERROR] FIFO not full after 4 bytes!");
// //         $finish;
// //     end

// //     //3. 데이터 1개 읽기 → full 플래그 꺼지는지 확인
// //         read_APB_data(4'h4, rd_data);
// //         $display("[FRD after 1st read] = 0x%02h", rd_data[7:0]);

// //         read_APB_data(4'h0, rd_data);
// //         $display("[FSR after 1st read] = %02b", rd_data[1:0]);
// //         if (rd_data[1] != 1'b0) begin
// //             $error("[ERROR] FIFO full flag did not clear after read!");
// //             $finish;
// //         end 

// //     // 4. 나머지 5개 데이터 읽기 및 검증
// //     for (int i = 1; i < 6; i++) begin
// //         read_APB_data(4'h4, rd_data);
// //         $display("[FRD] = 0x%02h", rd_data[7:0]);
// //         if (rd_data[7:0] !== test_data[i]) begin
// //             $error("[ERROR] Mismatch! Expected 0x%02h, Got: 0x%02h",
// //                    test_data[i], rd_data[7:0]);
// //             $finish;
// //         end
// //     end

// //     // 5. empty 플래그 확인 (fsr[0] == 1)
// //     read_APB_data(4'h0, rd_data);
// //     $display("[FSR final] = %02b", rd_data[1:0]);
// //     @(posedge rx_intf.PCLK);
// //     if (rd_data[0] != 1'b1) begin
// //         $error("[ERROR] FIFO not empty after all reads!");
// //         $finish;
// //     end

// //     $display("\n[TEST] Full/Empty test completed successfully!");
// //     end
// // endmodule

// //     // 3. 테스트 루프 (5개 데이터 전송 및 검증)
// //     for (int i = 0; i < 5; i++) begin
// //         $display("\n[TEST] Sending UART byte: 0x%02h", test_data[i]);
// //         rx_intf.send_uart_byte(test_data[i]);
// //         repeat (1000) @(posedge rx_intf.PCLK);

// //         // 4. FIFO empty 플래그 clear될 때까지 대기 (fsr[0] == 0)
// //         fork : fifo_empty_wait
// //             begin
// //                 do begin
// //                     read_APB_data(4'h0, rd_data);  // FSR 읽기
// //                     $display("[FSR] = %02b", rd_data[1:0]);
// //                     @(posedge rx_intf.PCLK);
// //                 end while (rd_data[0] ==
// //                            1'b1);  // empty 상태면 계속 대기
// //             end
// //             begin
// //                 #(100_000 * 10ns);  // 1ms 타임아웃
// //                 $error("[ERROR] FIFO Timeout waiting for byte 0x%02h",
// //                        test_data[i]);
// //                 $finish;
// //             end
// //         join_any
// //         disable fifo_empty_wait;

// //     //5. FRD 읽기 및 검증
// //         read_APB_data(4'h4, rd_data);  // 실제 수신 데이터 확인
// //         $display("[FRD] = 0x%02h", rd_data[7:0]);
// //         if (rd_data[7:0] !== test_data[i]) begin
// //             $error("[ERROR] Mismatch! Expected 0x%02h, Got: 0x%02h",
// //                    test_data[i], rd_data[7:0]);
// //             $finish;
// //         end
// // end

// //     // 6. 시뮬레이션 종료 메시지
// //     $display("\n[TEST] Simulation completed successfully!");
// //     //$finish;
// // initial begin
// //   // 1. 초기화 및 리셋

// //   rx_intf.PCLK = 0;
// //   rx_intf.PRESET = 1;
// //   rx_intf.RX = 1;  // UART RX 라인 기본값은 HIGH

// //   repeat (2) @(posedge rx_intf.PCLK);
// //   rx_intf.PRESET = 0;

// //   // 2. UART 데이터 전송

// //   repeat (10) @(posedge rx_intf.PCLK);
// //   $display("[TEST] Sending UART byte: 0x5A");
// //   rx_intf.send_uart_byte(8'h5A);
// //   repeat (1000) @(posedge rx_intf.PCLK);  // 충분한 대기 시간


// //   // FIFO empty 대기 (최대 1ms)
// //   fork : fifo_empty_check
// //     begin
// //       do begin
// //         read_APB_data(4'h0, rd_data);  // FSR 읽기
// //         @(posedge rx_intf.PCLK);
// //       end while (rd_data[0] == 1'b1);  // empty=1인 동안 반복

// //     end
// //     begin
// //       #(100_000 * 10ns);  // 100MHz 기준 1ms

// //       $display("[ERROR] FIFO Timeout waiting for empty flag!!");
// //       $finish;
// //     end
// //   join_any
// //   disable fifo_empty_check;

// // // FRD 읽기 (empty 재검증 후 수행)
// //   read_APB_data(4'h0, rd_data[1:0]); // FSR 재확인[3]
// //   $display("[FSR] = %02h Not EMPTY!", rd_data[7:0]);
// //   @(posedge rx_intf.PCLK);
// //   @(posedge rx_intf.PCLK);
// //   if (rd_data[0] == 1'b0) begin
// //     read_APB_data(4'h4, rd_data);
// //     $display("[FRD] = %02h", rd_data[7:0]);
// //     if (rd_data[7:0] !== 8'h5A) begin // 데이터 검증 추가
// //       $error("[ERROR] 0x5A mismatch! Got: 0x%h", rd_data[7:0]);
// //       $finish;
// //     end
// //   end else begin
// //     $error("[ERROR] FIFO empty after wait!");
// //     $finish;
// //   end

// //   // 5. 두 번째 UART 데이터 전송 및 검증

// //   repeat (5) @(posedge rx_intf.PCLK);
// //   $display("[TEST] Sending second UART byte: 0xA5");
// //   rx_intf.send_uart_byte(8'hA5);
// //   repeat (1000) @(posedge rx_intf.PCLK);  // 충분한 대기 시간


// //   // 두 번째 FIFO empty 대기
// //   fork : fifo_empty_check_2
// //       begin
// //       do begin
// //           read_APB_data(4'h0, rd_data);
// //           @(posedge rx_intf.PCLK);
// //       end while (rd_data[0] == 1'b1);
// //       end
// //       begin
// //       #(100_000 * 10ns);
// //       $display("[ERROR] FIFO Timeout for 0xA5!");
// //       $finish;
// //       end
// //   join_any
// //   disable fifo_empty_check_2;

// //   // 두 번째 FRD 읽기 및 검증
// //   read_APB_data(4'h0, rd_data);
// //   if (rd_data[0] == 1'b0) begin
// //     read_APB_data(4'h4, rd_data);
// //     $display("[FRD] = %02h", rd_data[7:0]);
// //     if (rd_data[7:0] !== 8'hA5) begin
// //       $error("[ERROR] 0xA5 mismatch! Got: 0x%h", rd_data[7:0]);
// //       $finish;
// //     end
// //   end

// //   // 7. 종료

// //   repeat (10) @(posedge rx_intf.PCLK);
// //   $display("[TEST] Simulation completed");
// //   //$finish;
// // end
