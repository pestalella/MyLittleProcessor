`timescale 1ns / 1ps

import constants_pkg::*;

module tb_alu_registers();
    bit clk;
    bit reset_n;

    always begin
        #5 clk = !clk;
    end

    bit [2:0] addr_a;
    bit [2:0] addr_b;
    bit [2:0] addr_r;
    bit [7:0] data_in;
//    logic [7:0] data_out;
    constants_pkg::ALUOp op;

    alu_registers dut(
        .clk(clk),
        .reset_n(reset_n),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .addr_r(addr_r),
        .data_in(data_in),
//        .data_out(data_out),
        .op(op));

    task check_register_value(input bit [2:0] reg_addr, input bit [7:0] expected_value);
        @(posedge clk) addr_a = reg_addr;
        op = REG_READ;
        @(posedge clk) begin
            if (dut.data_out === 'hzz)
                $error("Expected 0x%02h in r%0d. Got zz instead", expected_value, reg_addr, dut.data_out);
            else if (dut.data_out != expected_value)
                $error("Expected 0x%02h in r%0d. Got 0x%02h instead", expected_value, reg_addr, dut.data_out);
            else
                $info("r%0d=0x%02h as expected", reg_addr, dut.data_out);
        end
    endtask

    task test_basic_sum();
        // r0 = 'h42
        @(posedge clk) addr_a = 0;
        data_in = 'h42;
        op = REG_WRITE;
        // r1 = 'h24
        @(posedge clk) addr_a = 1;
        data_in = 'h24;
        op = REG_WRITE;
        // r2 = r0 + r1
        @(posedge clk) addr_a = 0;
        addr_b = 1;
        addr_r = 2;
        op = ADD;
        check_register_value(.reg_addr(0), .expected_value('h42));
        check_register_value(.reg_addr(1), .expected_value('h24));
        check_register_value(.reg_addr(2), .expected_value('h66));
    endtask

    task test_fibonacci();
        // r0 = 'h42
        @(posedge clk) addr_a = 0;
        data_in = 'h00;
        op = REG_WRITE;
        @(posedge clk) addr_a = 1;
        data_in = 'h01;
        op = REG_WRITE;
        @(posedge clk) addr_a = 2;
        data_in = 'h01;
        op = REG_WRITE;
        // compute next fibonacci value
        @(posedge clk) addr_a = 1;
        addr_b = 2;
        addr_r = 3;
        op = ADD;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk) addr_a = 2;
        addr_b = 3;
        addr_r = 4;
        op = ADD;
        @(posedge clk);
        @(posedge clk) addr_a = 3;
        addr_b = 4;
        addr_r = 5;
        op = ADD;
        @(posedge clk);
        @(posedge clk) addr_a = 4;
        addr_b = 5;
        addr_r = 6;
        op = ADD;
        @(posedge clk);
        @(posedge clk) addr_a = 5;
        addr_b = 6;
        addr_r = 7;
        op = ADD;
        @(posedge clk);
        check_register_value(.reg_addr(0), .expected_value('h00));
        check_register_value(.reg_addr(1), .expected_value('h01));
        check_register_value(.reg_addr(2), .expected_value('h01));
        check_register_value(.reg_addr(3), .expected_value('h02));
        check_register_value(.reg_addr(4), .expected_value('h03));
        check_register_value(.reg_addr(5), .expected_value('h05));
        check_register_value(.reg_addr(6), .expected_value('h08));
        check_register_value(.reg_addr(7), .expected_value('h0d));
    endtask

    initial begin
        clk = 0;
        // reset the DUT
        reset_n = 0;
        @(posedge clk) reset_n = 1;
        test_basic_sum();
        test_fibonacci();
    end
endmodule
