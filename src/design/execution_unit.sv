`ifndef EXECUTION_UNIT_SV
`define EXECUTION_UNIT_SV

`timescale 1ns / 1ps

`include "constants_pkg.sv"
`include "isa_definition.sv"

import constants_pkg::*;
import isa_pkg::*;

module exec_unit #(parameter DATA_BITS = 8) (
    input wire clk,
    input wire reset
);

    bit [constants_pkg::INSTRUCTION_POINTER_BITS-1:0] pc;
    bit [15:0] ir;

    logic [constants_pkg::MEMORY_ADDRESS_BITS-1:0] mem_address;
    logic [constants_pkg::MEMORY_DATA_BITS-1:0] mem_data;
    logic [constants_pkg::MEMORY_DATA_BITS-1:0] data_read;
    logic mem_read_en, mem_write_en;
    bit instruction_ready;
    enum bit [2:0] {IDLE, READ_HIGH_IR, READ_LOW_IR, DECODE} prev_state, state;


    ram #(.ADDR_BITS(constants_pkg::MEMORY_ADDRESS_BITS), 
          .DATA_BITS(constants_pkg::MEMORY_DATA_BITS))
        memory(.address(mem_address),
               .out_en(mem_read_en),
               .write_en(mem_write_en));
    assign memory.data = mem_data;


    logic subtract;
    logic carry;
    wire [REGISTER_DATA_BITS-1:0] alu_input_a, alu_input_b, alu_output, 
                                  register_file_input, regfile_rd0_data;
    bit [REGISTER_DATA_BITS-1:0] inst_immediate;
    bit [REGISTER_ADDRESS_BITS-1:0] reg_rd0_addr, reg_rd1_addr, reg_wr_addr;
    bit reg_rd0_en, reg_rd1_en, reg_wr_en;
    bit alu_inputA_sel, reg_input_sel;
    bit alu_zero;

    alu #(.DATA_BITS(REGISTER_DATA_BITS)) 
        arith_unit(.a(alu_input_a), 
                   .b(alu_input_b), 
                   .cin(subtract), 
                   .result(alu_output), 
                   .cout(carry));

    reg_mux2to1 alu_inputA_mux(.sel(alu_inputA_sel),
                               .in0(regfile_rd0_data),
                               .in1(inst_immediate),
                               .out(alu_input_a));

    register_file #(.ADDR_BITS(REGISTER_ADDRESS_BITS), 
                    .DATA_BITS(REGISTER_DATA_BITS))
        registers(.clk(clk), 
                  .reset(reset),

                  .rd0_enable(reg_rd0_en), 
                  .rd0_addr(reg_rd0_addr), 
                  .rd0_data(regfile_rd0_data), 

                  .rd1_enable(reg_rd1_en),
                  .rd1_addr(reg_rd1_addr),
                  .rd1_data(alu_input_b),

                  .wr_enable(reg_wr_en),
                  .wr_addr(reg_wr_addr),
                  .wr_data(register_file_input));
    
    reg_mux2to1 reg_input_mux(.sel(reg_input_sel),
                              .in0(alu_output),
                              .in1(inst_immediate),
                              .out(register_file_input));

    bit pc_offset_sel;
    wire [JUMP_OFFSET_BITS-1:0] next_pc_input;
    bit [JUMP_OFFSET_BITS-1:0] jump_dest;

    reg_mux2to1 #(.DATA_BITS(JUMP_OFFSET_BITS)) 
        pc_offset_mux(.sel(pc_offset_sel),
                      .in0((state==READ_LOW_IR)? pc + 2 : pc),
                      .in1(jump_dest),
                      .out(next_pc_input));

    always @(posedge reset) begin
        pc <= 0;
        pc_offset_sel <= 0;
        jump_dest <= 0;
        ir <= 0;
        alu_zero <= 0;
        mem_address <= 0;
        mem_data <= 'bzz;
        mem_read_en <= 0;
        mem_write_en <= 0;
        state <= IDLE;
        prev_state <= IDLE;
        instruction_ready <= 0;
    end;

    always @(posedge clk) begin
        if (state != IDLE)
            pc <= next_pc_input;
    end

    always @(posedge clk) begin
        mem_data <= 'bzz;
        case (state)
            READ_HIGH_IR: begin
                if (prev_state == READ_LOW_IR) begin
                    ir[7:0] <= memory.data;
                    instruction_ready <= 1;
                    // Return to regular increase of the instruction pointer
                    pc_offset_sel <= 0;
                end else begin 
                    instruction_ready <= 0;
                end
                // Prepare read transaction
                mem_address <= pc;
                mem_read_en <= 1;
                prev_state <= READ_HIGH_IR;
                state <= READ_LOW_IR;
            end
            READ_LOW_IR: begin
                instruction_ready <= 0;
                // Now read the data from the completed read transaction
                ir[15:8] <= memory.data;
                // And prepare next transaction
                mem_address <= pc + 1;
                mem_read_en <= 1;
                prev_state <= READ_LOW_IR;
                state <= READ_HIGH_IR;
            end
            DECODE: begin
                state <= IDLE;
            end
            IDLE: begin
                state <= READ_HIGH_IR;
            end
        endcase
    end

    always @(posedge instruction_ready) begin
        $display("Instruction ready: ir=%h%h opcode=%04b", ir[15:8], ir[7:0], ir[15:12]);
        
        // By default, pc = pc + 2
        pc_offset_sel <= 0;

        reg_wr_en      <= 0;
        reg_rd0_en     <= 0;
        reg_rd1_en     <= 0;

        case (ir[15:12])
            MOVIR: begin
                $display("mov r%0d #%h", ir[11:8], ir[7:0]);
                reg_wr_addr    <= ir[10:8];
                inst_immediate <= ir[7:0];
                reg_input_sel  <= 1;
                reg_wr_en      <= 1;
                reg_rd0_en     <= 0;
                reg_rd1_en     <= 0;
            end
            MOVRR: begin
                $display("mov reg reg");
            end
            MOVMR: begin
                $display("mov reg @address");
            end
            MOVRM: begin
                $display("mov @address reg");
            end
            ADDRR: begin
                $display("add reg reg reg");
            end
             ADDI: begin
                $display("add reg #imm");
            end
            SUBRR: begin
                $display("sub r%0d r%0d r%0d", ir[10:8], ir[6:4], ir[2:0]);
                reg_rd0_addr <= ir[6:4];
                reg_rd1_addr <= ir[2:0];
                reg_wr_addr  <= ir[10:8];
                subtract <= 1;
                reg_input_sel  <= 0;
                alu_inputA_sel <= 0;
                reg_wr_en      <= 1;
                reg_rd0_en     <= 1;
                reg_rd1_en     <= 1;
            end
             SUBI: begin
                $display("sub reg #imm");
            end
              JZI: begin
                $display("jz #%0d", ir[7:0]);
                // if (alu_zero) end
                    pc_offset_sel <= 1;
                    jump_dest <= ir[7:0];
                // end
            end
              JZR: begin 
                $display("jz reg");
                pc_offset_sel <= 0;
            end
              NOP: begin
                $display("nop");
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase
    end

endmodule
`endif