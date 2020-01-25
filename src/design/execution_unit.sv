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

    logic wr_mem_en;
    logic [MEMORY_DATA_BITS-1:0] wr_mem_data;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_mem_addr;

    bit mem_write_in_progress;
    ExecutionStage state;

    assign rd_ram_en = rd_mem_en;
    assign wr_ram_en = wr_mem_en;
    assign rd_ram_addr = rd_mem_addr;
    assign wr_ram_addr = wr_mem_addr;
    assign wr_ram_data = mem_write_in_progress ? wr_mem_data : {DATA_BITS{1'bz}}; // To drive the inout net

    logic subtract;
    logic alu_carry;
    logic alu_zero;
    wire [REGISTER_DATA_BITS-1:0] alu_input_b, alu_output,
                                  register_file_input, regfile_rd0_data, regfile_rd1_data;
    bit [REGISTER_DATA_BITS-1:0] inst_immediate, load_mem;
    bit [REGISTER_ADDRESS_BITS-1:0] reg_rd0_addr, reg_rd1_addr, reg_wr_addr;
    bit reg_rd0_en, reg_rd1_en, reg_wr_en;
    enum bit {REGISTER_FILE, IMMEDIATE} alu_inputB_sel;
    bit save_alu_flags;

    enum bit[1:0] {ALU_OUTPUT = 0,
                   INST_IMMEDIATE = 1,
                   MEM_LOAD = 2,
                   REG_FILE_RD0 = 3} reg_input_sel;

    alu #(.DATA_BITS(REGISTER_DATA_BITS))
        arith_unit(.clk(clk),
                   .reset(reset),
                   .a(regfile_rd0_data),
                   .b(alu_input_b),
                   .cin(subtract),
                   .result(alu_output),
                   .cout(alu_carry),
                   .zero(alu_zero));

    mux2to1 alu_inputB_mux(.sel(alu_inputB_sel),
                               .in0(regfile_rd1_data),
                               .in1(inst_immediate),
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

    function void request_register_reads;
        case (ir[15:12])
            MOVIR: begin
            end
            LOAD: begin
            end
            STORE: begin
                reg_rd0_addr <= ir[10:8];
                reg_rd0_en   <= 1;
            end
            ADDRR: begin
                reg_rd0_addr <= rd_ram_data[6:4];
                reg_rd1_addr <= rd_ram_data[2:0];
                reg_rd0_en     <= 1;
                reg_rd1_en     <= 1;
                // Enable input to the ALU from the register file
                alu_inputB_sel <= REGISTER_FILE;
                // Addition op, therefore subtract=0
                subtract       <= 0;
            end
             ADDI: begin
                reg_rd0_addr   <= ir[10:8];
                reg_rd0_en     <= 1;
                inst_immediate <= rd_ram_data[7:0];
                // Enable input to the ALU from the constant in the instruction
                alu_inputB_sel <= IMMEDIATE;
                // Addition op, therefore subtract=0
                subtract       <= 0;
            end
            SUBRR: begin
                reg_rd0_addr  <= rd_ram_data[6:4];
                reg_rd1_addr  <= rd_ram_data[2:0];
                reg_rd0_en    <= 1;
                reg_rd1_en    <= 1;
                // Enable input to the ALU from the register file
                alu_inputB_sel <= REGISTER_FILE;
                // Subtract op, therefore subtract=1
                subtract <= 1;
            end
             SUBI: begin
                reg_rd0_addr   <= ir[10:8];
                reg_rd0_en     <= 1;
                inst_immediate <= rd_ram_data[7:0];
                alu_inputB_sel <= IMMEDIATE;
                // Subtract op, therefore subtract=1
                subtract <= 1;
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
        reg_input_sel <= ALU_OUTPUT;
        reg_wr_en     <= 0;
        reg_rd0_en    <= 0;
        reg_rd1_en    <= 0;
        rd_mem_en     <= 0;

        case (ir[15:12])
            MOVIR: begin
                $display("mov r%0d #%h", ir[10:8], ir[7:0]);
                reg_wr_addr    <= ir[10:8];
                inst_immediate <= ir[7:0];
                reg_input_sel  <= INST_IMMEDIATE;
                reg_wr_en      <= 1;
            end
            LOAD: begin
                $display("load r%0d @%h", ir[10:8], ir[7:0]);
                // Prepare next transaction
                rd_mem_addr   <= ir[7:0];
                rd_mem_en     <= 1;
                reg_wr_addr   <= ir[10:8];
                reg_wr_en     <= 1;
                reg_input_sel <= MEM_LOAD;
            end
            STORE: begin
                $display("store @%h r%0d", ir[7:0], ir[10:8]);
                // Launch memory write
                wr_mem_addr           <= ir[7:0];
                wr_mem_data           <= regfile_rd0_data;
                mem_write_in_progress <= 1;
                wr_mem_en             <= 1;
                rd_mem_en             <= 0;
            end
            ADDRR: begin
                $display("add r%0d r%0d r%0d", ir[10:8], ir[6:4], ir[2:0]);
                // Enable writes to the register file from the ALU
                reg_input_sel  <= ALU_OUTPUT;
                reg_wr_addr  <= ir[10:8];
                reg_wr_en      <= 1;
                // Addition op, therefore subtract=0
                subtract <= 0;
            end
             ADDI: begin
                $display("add r%0d #%h", ir[10:8], ir[7:0]);
                // Enable writes to the register file from the ALU
                reg_input_sel  <= ALU_OUTPUT;
                reg_wr_addr    <= ir[10:8];
                reg_wr_en      <= 1;
            end
            SUBRR: begin
                $display("sub r%0d r%0d r%0d", ir[10:8], ir[6:4], ir[2:0]);
                // Enable writes to the register file from the ALU
                reg_input_sel <= ALU_OUTPUT;
                reg_wr_addr   <= ir[10:8];
                reg_wr_en     <= 1;
            end
             SUBI: begin
                $display("sub r%0d #%h", ir[10:8], ir[7:0]);
                // Enable writes to the register file from the ALU
                reg_input_sel  <= ALU_OUTPUT;
                reg_wr_addr    <= ir[10:8];
                reg_wr_en      <= 1;
                // Subtraction op, therefore subtract=1
                subtract       <= 1;
            end
             JNZI: begin
                $display("jnz #%0d", ir[7:0]);
            end
              JZR: begin
                $display("jz reg");
                pc_offset_sel <= NEXT_INSTRUCTION;
            end
              NOP: begin
                $display("nop");
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase

    endfunction

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            pc_offset_sel     <= RESET;
            rd_mem_addr       <= 0;
            wr_mem_addr       <= 0;
            rd_mem_en         <= 0;
            wr_mem_en         <= 0;
            mem_write_in_progress <= 0;
            reg_rd0_addr      <= 0;
            reg_rd1_addr      <= 0;
            reg_wr_addr       <= 0;
            subtract          <= 0;
            carry_flag        <= 0;
            zero_flag         <= 0;
            save_alu_flags    <= 0;
            reg_input_sel     <= ALU_OUTPUT;
            alu_inputB_sel    <= REGISTER_FILE;
            reg_wr_en         <= 0;
            reg_rd0_en        <= 0;
            reg_rd1_en        <= 0;
            reg_wr_en         <= 0;
            state             <= IDLE;
            current_inst      <= NOP;
            jump_dest         <= 0;
        end else begin
            case (state)
                FETCH_MSB_IR: begin
                    // save ALU flags from previous instruction if necessary
                    zero_flag   <= save_alu_flags ? alu_zero : zero_flag;
                    carry_flag  <= save_alu_flags ? alu_carry : carry_flag;
                    // Prepare read transaction
                    rd_mem_addr <= pc;
                    rd_mem_en   <= 1;
                    wr_mem_en   <= 0;
                    reg_wr_en   <= 0;
                    state       <= FETCH_LSB_IR;
                end
                FETCH_LSB_IR: begin
                    // Now read the data from the completed read transaction
                    ir[15:8]    <= rd_ram_data;
                    current_inst <= OpCode'(rd_ram_data[7:4]);
                    // And prepare next transaction
                    rd_mem_addr <= pc + 1;
                    rd_mem_en   <= 1;
                    state       <= DECODE;
                end
                DECODE: begin
                    // Tentatively update the program counter
                    // to the next instruction
                    pc_offset_sel <= NEXT_INSTRUCTION;

                    // Need to compute the jump target early, otherwise
                    // the instruction right after the jnz is executed
                    // before branching
                    if (ir[15:12] == JNZI) begin
                        if (~zero_flag) begin
                            pc_offset_sel <= JUMP_TARGET;
                            jump_dest <= rd_ram_data;
                        end
                    end
                    ir[7:0]      <= rd_ram_data;
                    rd_mem_en    <= 0;
                    wr_mem_en    <= 0;

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
                    else
                        state <= FETCH_MSB_IR;
                end
                LOAD_STAGE: begin
                    load_mem  <= rd_ram_data;
                    wr_mem_en <= 0;
                    rd_mem_en <= 0;
                    state     <= FETCH_MSB_IR;
                end
                STORE_STAGE: begin
                    wr_mem_en             <= 0;
                    mem_write_in_progress <= 0;
                    state                 <= FETCH_MSB_IR;
                end
                IDLE: begin
                    state <= FETCH_MSB_IR;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
`endif