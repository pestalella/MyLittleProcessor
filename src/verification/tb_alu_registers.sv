`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/25/2019 07:21:31 PM
// Design Name: 
// Module Name: tb_alu_registers
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
import constants_pkg::*;

module tb_alu_registers();
    bit clk;
    bit reset;
    
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
        .reset(reset), 
        .addr_a(addr_a), 
        .addr_b(addr_b),
        .addr_r(addr_r),
        .data_in(data_in),
//        .data_out(data_out),
        .op(op));


    task check_register_value(input bit [2:0] reg_addr, input bit [7:0] expected_value);
        @(posedge clk) addr_a = reg_addr;
        op = REG_READ;
        @(negedge clk) begin
            if (dut.data_out === 'hzz)
                $error("Expected %02h in r%0d. Got zz instead", expected_value, reg_addr, dut.data_out);
            else if (dut.data_out != expected_value)
                $error("Expected %02h in r%0d. Got %02h instead", expected_value, reg_addr, dut.data_out);
            else
                $info("r%0d=%02h as expected", reg_addr, dut.data_out);
        end
    endtask
    
    task test_basic_sum();
        // r0 = 'h42
        @(posedge clk) addr_a = 0;
        data_in = 'h42;
        op = REG_WRITE;
        @(negedge clk) check_register_value(.reg_addr(0), .expected_value('h42));
        // r1 = 'h24
        @(posedge clk) addr_a = 1;
        data_in = 'h24;
        op = REG_WRITE;
        @(negedge clk) check_register_value(.reg_addr(1), .expected_value('h24));
        // r2 = r0 + r1
        @(posedge clk) addr_a = 0;
        addr_b = 1;
        addr_r = 2;
        op = ADD;
        @(posedge clk) check_register_value(.reg_addr(2), .expected_value('h66));
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
        @(posedge clk) addr_a = 2;
        addr_b = 3;
        addr_r = 4;
        op = ADD;
        @(posedge clk) addr_a = 3;
        addr_b = 4;
        addr_r = 5;
        op = ADD;
        @(posedge clk) addr_a = 4;
        addr_b = 5;
        addr_r = 6;
        op = ADD;
        @(posedge clk) addr_a = 5;
        addr_b = 6;
        addr_r = 7;
        op = ADD;
    endtask

    initial begin
        clk = 0;
        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;
        test_basic_sum();
        test_fibonacci();
    end
endmodule
