`ifndef ALU_REGISTERS_SV
`define ALU_REGISTERS_SV

`timescale 1ns / 1ps

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
        
    logic subtract;
    logic carry;
    wire [DATA_BITS-1:0] alu_input_a, alu_input_b, alu_output, register_file_input;
    logic rd0_enable, rd1_enable, wr_enable;
    logic [ADDR_BITS-1:0] rd0_addr, rd1_addr, wr_addr;

    bit reg_input_sel;

    alu #(.DATA_BITS(DATA_BITS)) 
        arith_unit(.a(alu_input_a), 
                   .b(alu_input_b), 
                   .cin(subtract), 
                   .result(alu_output), 
                   .cout(carry));

    register_file #(.ADDR_BITS(ADDR_BITS), 
                    .DATA_BITS(DATA_BITS))
        registers(.clk(clk), 
                  .reset(reset),
                  .rd0_addr(rd0_addr), 
                  .rd1_addr(rd1_addr), 
                  .wr_addr(wr_addr), 
                  .rd0_data(alu_input_a), 
                  .rd1_data(alu_input_b),
                  .wr_data(register_file_input),
                  .rd0_enable(rd0_enable), 
                  .rd1_enable(rd1_enable),
                  .wr_enable(wr_enable));
    
    reg_mux2to1 reg_input_mux(.sel(reg_input_sel),
                              .in0(alu_output),
                              .in1(data_in),
                              .out(register_file_input));

    assign data_out = registers.rd0_data;

    initial begin
        subtract <= 0;
        rd0_enable <= 0;
        rd1_enable <= 0;
        wr_enable <= 0;
        reg_input_sel <= 0;
    end

    always @(posedge clk) begin
        case (op)
            REG_READ: begin  // data_out = rA
                rd0_addr <= addr_a;
                rd0_enable <= 1;
                rd1_enable <= 0;
                wr_enable <= 0;
                reg_input_sel <= 0;
                end
            REG_WRITE: begin  // rA = data_in
                wr_addr <= addr_a;
                reg_input_sel <= 1;
                wr_enable <= 1;
                rd0_enable <= 0;
                rd1_enable <= 0;
                end
            ADD: begin  // rR = rA + rB;
                rd0_addr <= addr_a;
                rd1_addr <= addr_b;
                wr_addr <= addr_r;
                rd0_enable <= 1;
                rd1_enable <= 1;
                wr_enable <= 1;
                subtract <= 0;
                reg_input_sel <= 0;
                end
            SUB: begin  // rR = rA - rB
                rd0_addr <= addr_a;
                rd1_addr <= addr_b;
                wr_addr <= addr_r;
                rd0_enable <= 1;
                rd1_enable <= 1;
                wr_enable <= 1;
                subtract <= 1;
                reg_input_sel <= 0;
                end
        endcase
    end
endmodule

`endif