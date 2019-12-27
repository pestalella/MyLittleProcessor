`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2019 11:41:09 PM
// Design Name: 
// Module Name: alu_registers
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
`include "constants_pkg.sv"

import constants_pkg::*;

module alu_registers(
    input wire clk,
    input wire reset,
    input wire [2:0] addr_a,
    input wire [2:0] addr_b,
    input wire [2:0] addr_r,
    input wire [7:0] data_in,
    output logic [7:0] data_out,
    input constants_pkg::ALUOp op
    );
        
    register_bus rd0_bus();
    register_bus rd1_bus();
    register_bus wr_bus();
    logic subtract;
    logic carry;
    
    alu arith_unit(.a(rd0_bus.data), 
                   .b(rd1_bus.data), 
                   .cin(subtract), 
                   .result(wr_bus.data), 
                   .cout(carry));

    register_file registers(.clk(clk), 
                            .reset(reset),
                            .rd0_bus(rd0_bus), 
                            .rd1_bus(rd1_bus), 
                            .wr_bus(wr_bus));

    assign data_out = rd0_bus.data;

    always @(posedge clk) begin
        case (op)
            REG_READ: begin  // data_out = rA
                rd0_bus.addr <= addr_a;
                rd0_bus.enable <= 1;
                #10
                rd0_bus.enable <= 0;
                rd1_bus.enable <= 0;
                wr_bus.enable <= 0;
                end
            REG_WRITE: begin  // rA = data_in
                rd0_bus.enable <= 0;
                rd1_bus.enable <= 0;
                wr_bus.addr <= addr_a;
                wr_bus.data <= data_in;
                wr_bus.enable <= 1;
                #10
                wr_bus.enable = 0;
                end
            ADD: begin  // rR = rA + rB;
                rd0_bus.addr <= addr_a;
                rd0_bus.enable <= 1;
                rd1_bus.addr <= addr_b;
                rd1_bus.enable <= 1;
                wr_bus.addr <= addr_r;
                wr_bus.enable <= 1;
                subtract <= 0;
                #10
                rd0_bus.enable = 0;
                rd1_bus.enable = 0;
                wr_bus.enable = 0;
                end
            SUB: begin  // rR = rA - rB
                rd0_bus.addr <= addr_a;
                rd0_bus.enable <= 1;
                rd1_bus.addr <= addr_b;
                rd1_bus.enable <= 1;
                wr_bus.addr <= addr_r;
                wr_bus.enable <= 1;
                subtract <= 1;
                #10
                rd0_bus.enable <= 0;
                rd1_bus.enable <= 0;
                wr_bus.enable <= 0;
            end                
        endcase
    end
endmodule
