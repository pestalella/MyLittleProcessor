`ifndef EXECUTION_UNIT_SV
`define EXECUTION_UNIT_SV

`timescale 1ns / 1ps

`include "alu.sv"
`include "constants_pkg.sv"
`include "isa_definition.sv"
`include "muxers.sv"
`include "register_file.sv"

import constants_pkg::*;
import isa_pkg::*;

module exec_unit #(parameter DATA_BITS = 8) (
    input wire clk,
    input wire reset,

    output wire rd_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr,
    input  wire [MEMORY_DATA_BITS-1:0] rd_ram_data,

    output wire wr_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr,
    output wire [MEMORY_DATA_BITS-1:0] wr_ram_data
);

    bit [constants_pkg::INSTRUCTION_POINTER_BITS-1:0] pc;
    bit [15:0] ir;
    bit carry_flag;
    bit zero_flag;

    logic rd_mem_en;
    logic [MEMORY_DATA_BITS-1:0] rd_mem_data;
    logic [MEMORY_ADDRESS_BITS-1:0] rd_mem_addr;

    logic mem_wr_en;
    logic [MEMORY_DATA_BITS-1:0] wr_mem_data;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_mem_addr;

    bit mem_wr_in_progress;
    ExecutionStage state;

    assign rd_ram_en = rd_mem_en;
    assign wr_ram_en = mem_wr_en;
    assign rd_ram_addr = rd_mem_addr;
    assign wr_ram_addr = wr_mem_addr;
    assign wr_ram_data = mem_wr_in_progress ? wr_mem_data : {DATA_BITS{1'bz}}; // To drive the inout net

    logic subtract;
    logic alu_carry;
    logic alu_zero;
    wire alu_zero_wire;
    wire [REGISTER_DATA_BITS-1:0] alu_input_b, alu_output,
                                  register_file_input, regfile_rd0_data, regfile_rd1_data;
    bit [REGISTER_DATA_BITS-1:0] inst_immediate, load_mem;
    bit [REGISTER_ADDRESS_BITS-1:0] reg_rd0_addr, reg_rd1_addr, reg_wr_addr;
    bit reg_rd0_en, reg_rd1_en, reg_wr_en;
    enum bit {IMMEDIATE, REGISTER_FILE} alu_inputB_sel;
    bit save_alu_flags;

    typedef enum bit[1:0] {ALU_OUTPUT = 0,
                           INST_IMMEDIATE = 1,
                           MEM_LOAD = 2,
                           REG_FILE_RD0 = 3} RegisterInputSelection;
    RegisterInputSelection reg_input_sel;

    alu #(.DATA_BITS(REGISTER_DATA_BITS))
        arith_unit(.clk(clk),
                   .reset(reset),
                   .a(regfile_rd0_data),
                   .b(alu_input_b),
                   .cin(subtract),
                   .result(alu_output),
                   .cout(alu_carry),
                   .zero(alu_zero_wire));

    mux2to1 alu_inputB_mux(.sel(alu_inputB_sel),
                               .in0(inst_immediate),
                               .in1(regfile_rd1_data),
                               .out(alu_input_b));

    register_file #(.ADDR_BITS(REGISTER_ADDRESS_BITS),
                    .DATA_BITS(REGISTER_DATA_BITS))
        registers(.clk(clk),
                  .reset(reset),

                  .rd0_enable(reg_rd0_en),
                  .rd0_addr(reg_rd0_addr),
                  .rd0_data(regfile_rd0_data),

                  .rd1_enable(reg_rd1_en),
                  .rd1_addr(reg_rd1_addr),
                  .rd1_data(regfile_rd1_data),

                  .wr_enable(reg_wr_en),
                  .wr_addr(reg_wr_addr),
                  .wr_data(register_file_input));

    mux4to1 reg_input_mux(.sel(reg_input_sel),
                              .in0(alu_output),
                              .in1(inst_immediate),
                              .in2(load_mem),
                              .in3(regfile_rd0_data),
                              .out(register_file_input));

    enum bit [1:0] {RESET = 0, NEXT_INSTRUCTION = 1, JUMP_TARGET = 2, NO_UPDATE = 3} pc_offset_sel;
    wire [JUMP_OFFSET_BITS-1:0] next_pc_input;
    bit [JUMP_OFFSET_BITS-1:0] jump_dest;

    mux4to1 #(.DATA_BITS(JUMP_OFFSET_BITS))
        pc_offset_mux(.sel(pc_offset_sel),
                      .in0('0),
                      .in1(8'(pc + 2)),
                      .in2(jump_dest),
                      .in3(pc),
                      .out(next_pc_input));

    // Mostly to show in waves what the current instruction is
    OpCode current_inst;

    always @(posedge clk) begin
        if (state != IDLE)
            pc <= next_pc_input;
    end

    logic instr_is_movir, instr_is_load, instr_is_store, instr_is_addrr, instr_is_addi,
          instr_is_subrr, instr_is_subi, instr_is_jnzi, instr_is_jzr, instr_is_nop;

    logic ex_instr_is_movir, ex_instr_is_load, ex_instr_is_store, ex_instr_is_addrr, ex_instr_is_addi,
          ex_instr_is_subrr, ex_instr_is_subi, ex_instr_is_jnzi, ex_instr_is_jzr, ex_instr_is_nop;

    logic instr_arithmetic;

    assign instr_is_movir = ~ir[15] & ~ir[14] & ~ir[13] & ~ir[12];
    assign instr_is_load  = ~ir[15] & ~ir[14] &  ir[13] & ~ir[12];
    assign instr_is_store = ~ir[15] & ~ir[14] &  ir[13] &  ir[12];
    assign instr_is_addrr = ~ir[15] &  ir[14] & ~ir[13] & ~ir[12];
    assign instr_is_addi  = ~ir[15] &  ir[14] & ~ir[13] &  ir[12];
    assign instr_is_subrr = ~ir[15] &  ir[14] &  ir[13] & ~ir[12];
    assign instr_is_subi  = ~ir[15] &  ir[14] &  ir[13] &  ir[12];
    assign instr_is_jnzi  =  ir[15] & ~ir[14] & ~ir[13] & ~ir[12];
    assign instr_is_jzr   =  ir[15] & ~ir[14] & ~ir[13] &  ir[12];
    assign instr_is_nop   =  ir[15] &  ir[14] &  ir[13] &  ir[12];

    assign ex_instr_is_movir =  (state == INSTR_FETCH_START)                          & ~ir[15] & ~ir[14] & ~ir[13] & ~ir[12];
    assign ex_instr_is_load  = ((state == INSTR_FETCH_START) | (state == LOAD_STAGE)) & ~ir[15] & ~ir[14] &  ir[13] & ~ir[12];
    assign ex_instr_is_store = ((state == INSTR_FETCH_START) | (state == LOAD_STAGE)) & ~ir[15] & ~ir[14] &  ir[13] &  ir[12];
    assign ex_instr_is_addrr =  (state == INSTR_FETCH_START)                          & ~ir[15] &  ir[14] & ~ir[13] & ~ir[12];
    assign ex_instr_is_addi  =  (state == INSTR_FETCH_START)                          & ~ir[15] &  ir[14] & ~ir[13] &  ir[12];
    assign ex_instr_is_subrr =  (state == INSTR_FETCH_START)                          & ~ir[15] &  ir[14] &  ir[13] & ~ir[12];
    assign ex_instr_is_subi  =  (state == INSTR_FETCH_START)                          & ~ir[15] &  ir[14] &  ir[13] &  ir[12];
    assign ex_instr_is_jnzi  =  (state == REGISTER_FETCH)                             &  ir[15] & ~ir[14] & ~ir[13] & ~ir[12];
    assign ex_instr_is_jzr   =  (state == INSTR_FETCH_START)                          &  ir[15] & ~ir[14] & ~ir[13] &  ir[12];
    assign ex_instr_is_nop   =  (state == INSTR_FETCH_START)                          &  ir[15] &  ir[14] &  ir[13] &  ir[12];

    assign rd_mem_en = (state == INSTR_FETCH_END) | (state == REGISTER_FETCH) | ex_instr_is_load;

    assign reg_rd0_en = instr_is_store |
                        instr_is_addrr | instr_is_addi |
                        instr_is_subrr | instr_is_subi;
    assign reg_rd1_en = instr_is_addrr | instr_is_subrr;
    assign subtract = (state == EXECUTE) && (instr_is_subrr | instr_is_subi);

    assign instr_arithmetic = instr_is_addrr | instr_is_addi |
                              instr_is_subrr | instr_is_subi;
    assign reg_wr_en = ((state == EXECUTE) && (instr_is_movir | instr_is_load)) |
                       ((state == REGISTER_WB) && (instr_is_addrr | instr_is_addi |
                                                   instr_is_subrr | instr_is_subi));

    assign reg_input_sel = (instr_is_load  && (state == EXECUTE)) ? MEM_LOAD :
                          ((instr_is_movir && (state == EXECUTE)) ? INST_IMMEDIATE :
                                                                    ALU_OUTPUT);
    assign alu_inputB_sel = (instr_is_addi || instr_is_subi ) && (state == EXECUTE) ? IMMEDIATE : REGISTER_FILE;
    assign alu_zero = (instr_arithmetic && (state == REGISTER_WB)) ? alu_zero_wire : alu_zero;

    function void request_register_reads;
        case (ir[15:12])
            MOVIR: begin
                reg_wr_addr    <= ir[10:8];
                inst_immediate <= rd_ram_data[7:0];
            end
            LOAD: begin
                reg_wr_addr    <= ir[10:8];
            end
            STORE: begin
                reg_rd0_addr   <= ir[10:8];
            end
            ADDRR: begin
                reg_rd0_addr   <= rd_ram_data[6:4];
                reg_rd1_addr   <= rd_ram_data[2:0];
                reg_wr_addr    <= ir[10:8];
            end
             ADDI: begin
                reg_rd0_addr   <= ir[10:8];
                reg_wr_addr    <= ir[10:8];
                inst_immediate <= rd_ram_data[7:0];
            end
            SUBRR: begin
                reg_rd0_addr   <= rd_ram_data[6:4];
                reg_rd1_addr   <= rd_ram_data[2:0];
                reg_wr_addr    <= ir[10:8];
            end
             SUBI: begin
                reg_rd0_addr   <= ir[10:8];
                reg_wr_addr    <= ir[10:8];
                inst_immediate <= rd_ram_data[7:0];
            end
             JNZI: begin
            end
              JZR: begin
            end
              NOP: begin
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase
    endfunction

    function void execute_instruction;

        case (ir[15:12])
            MOVIR: begin
                $display("mov r%0d #%h", ir[10:8], ir[7:0]);
            end
            LOAD: begin
                $display("load r%0d @%h", ir[10:8], ir[7:0]);
                // Prepare next transaction
                rd_mem_addr   <= ir[7:0];
            end
            STORE: begin
                $display("store @%h r%0d", ir[7:0], ir[10:8]);
                // Launch memory write
                wr_mem_addr        <= ir[7:0];
                wr_mem_data        <= regfile_rd0_data;
                mem_wr_in_progress <= 1;
                mem_wr_en          <= 1;
            end
            ADDRR: begin
                $display("add r%0d r%0d r%0d", ir[10:8], ir[6:4], ir[2:0]);
                // Enable writes to the register file from the ALU
            end
             ADDI: begin
                $display("add r%0d #%h", ir[10:8], ir[7:0]);
                // Enable writes to the register file from the ALU
            end
            SUBRR: begin
                $display("sub r%0d r%0d r%0d", ir[10:8], ir[6:4], ir[2:0]);
                // Enable writes to the register file from the ALU
            end
             SUBI: begin
                $display("sub r%0d #%h", ir[10:8], ir[7:0]);
                // Enable writes to the register file from the ALU
            end
             JNZI: begin
                $display("jnz #%0d", ir[7:0]);
            end
              JZR: begin
                $display("jz reg");
            end
              NOP: begin
                $display("nop");
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase

    endfunction

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            pc_offset_sel      <= RESET;
            rd_mem_addr        <= '0;
            wr_mem_addr        <= '0;
            mem_wr_en          <= 0;
            mem_wr_in_progress <= 0;
            reg_rd0_addr       <= '0;
            reg_rd1_addr       <= '0;
            reg_wr_addr        <= '0;
            carry_flag         <= 0;
            zero_flag          <= 0;
            save_alu_flags     <= 0;
            state              <= IDLE;
            current_inst       <= NOP;
            jump_dest          <= 0;
        end else begin
            case (state)
                INSTR_FETCH_START: begin
                    // save ALU flags from previous instruction if necessary
                    zero_flag   <= save_alu_flags ? alu_zero : zero_flag;
                    carry_flag  <= save_alu_flags ? alu_carry : carry_flag;
                    // Prepare read transaction
                    rd_mem_addr <= pc;
                    mem_wr_en   <= 0;
                    state       <= INSTR_FETCH_END;
                end
                INSTR_FETCH_END: begin
                    // Now read the data from the completed read transaction
                    ir[15:8]    <= rd_ram_data;
                    current_inst <= OpCode'(rd_ram_data[7:4]);
                    // And prepare next transaction
                    rd_mem_addr <= pc + 1;

                    state       <= REGISTER_FETCH;
                end
                REGISTER_FETCH: begin
                    // Read the second half of the instruction
                    ir[7:0]      <= rd_ram_data;

                    // Need to compute the jump target early, otherwise the instruction
                    // right after the jnz is executed before branching
                    jump_dest <= rd_ram_data;
                    pc_offset_sel <= (ex_instr_is_jnzi & ~zero_flag) ? JUMP_TARGET : NEXT_INSTRUCTION;

                    mem_wr_en    <= 0;

                    request_register_reads();

                    state        <= EXECUTE;
                end
                EXECUTE: begin
                    // Program counter updates happened in the previous stage
                    // No updates until next instruction
                    pc_offset_sel <= NO_UPDATE;

                    execute_instruction();

                    save_alu_flags <= (ir[15:12] == ADDI) | (ir[15:12] == ADDRR) |
                                      (ir[15:12] == SUBI) | (ir[15:12] == SUBRR);

                    if (ir[15:12] == LOAD)
                        state <= LOAD_STAGE;
                    else if (ir[15:12] == STORE)
                        state <= STORE_STAGE;
                    else if (instr_arithmetic)
                        state <= REGISTER_WB;
                    else
                        state <= INSTR_FETCH_START;
                end
                REGISTER_WB: begin
                    state     <= INSTR_FETCH_START;
                end
                LOAD_STAGE: begin
                    load_mem  <= rd_ram_data;
                    mem_wr_en <= 0;
                    state     <= INSTR_FETCH_START;
                end
                STORE_STAGE: begin
                    mem_wr_en             <= 0;
                    mem_wr_in_progress <= 0;
                    state                 <= INSTR_FETCH_START;
                end
                IDLE: begin
                    state <= INSTR_FETCH_START;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
`endif