`timescale 1ns / 1ps

interface adder_intf;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] sum;
    logic       carry;
endinterface  //adder_intf

class transaction;
    //랜덤 값을 넣어줄 거란 rand
    rand bit [7:0] a; //bit는 0과 1만 들어감 
    rand bit [7:0] b;
endclass //transaction

class generator;
    transaction tr; //클래스 이름 변수; 
    mailbox #(transaction) gen2drv_mbox; //클래스 이름 gen2drv_mbox :데이터 타입 형태의 메일박스이다

    function new(mailbox#(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
    endfunction //new()

    task run(int run_count);
        repeat (run_count) begin
            tr = new();
            tr.randomize();
            gen2drv_mbox.put(tr); //랜덤값을 메일박스에 넣어줌줌
            #10;
        end
    endtask //automatic
endclass //generator

class driver;
    transaction tr;
    virtual adder_intf adder_if;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox#(transaction) gen2drv_mbox, virtual adder_intf adder_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.adder_if = adder_if;
    endfunction //new

    task reset();
        adder_if.a = 0;
        adder_if.b = 0;
    endtask //reset

    task run ();
        forever begin
            gen2drv_mbox.get(tr);
            adder_if.a = tr.a;
            adder_if.b = tr.b;
            #10;
        end
    endtask //run
endclass //driver

class envirnment;
    generator gen;
    driver drv;
    mailbox #(transaction) gen2drv_mbox;

    function new(virtual adder_intf adder_if);
        gen2drv_mbox = new();
        gen = new(gen2drv_mbox);
        drv = new(gen2drv_mbox, adder_if);
    endfunction //new()

    task run();
        fork
            gen.run(10000);
            drv.run();
        join_any
        #10 $finish;
    endtask //run
endclass //envirnment

module tb_adder ();
    envirnment env;
    adder_intf adder_if();

    adder dut(
        .a(adder_if.a),
        .b(adder_if.b),
        .sum(adder_if.sum),
        .carry(adder_if.carry)
    );

    initial begin
        env = new(adder_if);
        env.run();
    end

endmodule

