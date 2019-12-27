`timescale 1ns / 1ps

`ifndef ALU_REGISTERS_SV
`define ALU_REGISTERS_SV

`include "constants_pkg.sv"

import constants_pkg::*;

module alu_registers #( parameter ADDR_BITS = 3, DATA_BITS = 8 ) (
    input wire clk,
    input wire reset,
    input wire [ADDR_BITS-1:0] addr_a,
    input wire [ADDR_BITS-1:0] addr_b,
    input wire [ADDR_BITS-1:0] addr_r,
    input wire [DATA_BITS-1:0] data_in,
    output logic [DATA_BITS-1:0] data_out,
    input constants_pkg::ALUOp op
    );
        
    register_bus #(.ADDR_BITS(ADDR_BITS), 
                   .DATA_BITS(DATA_BITS)) rd0_bus();
    register_bus #(.ADDR_BITS(ADDR_BITS), 
                   .DATA_BITS(DATA_BITS)) rd1_bus();
    register_bus #(.ADDR_BITS(ADDR_BITS), 
                   .DATA_BITS(DATA_BITS)) wr_bus();
    logic subtract;
    logic carry;
    
    alu #(.DATA_BITS(DATA_BITS)) 
        arith_unit(.a(rd0_bus.data), 
                   .b(rd1_bus.data), 
                   .cin(subtract), 
                   .result(wr_bus.data), 
                   .cout(carry));

    register_file #(.ADDR_BITS(ADDR_BITS), 
                    .DATA_BITS(DATA_BITS))
        registers(.clk(clk), 
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

`endif