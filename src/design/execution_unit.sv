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
    input  wire clk,
    input  wire reset_n,

    output wire rd_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr,
    input  wire [MEMORY_DATA_BITS-1:0] rd_ram_data,

    output wire wr_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr,
    output wire [MEMORY_DATA_BITS-1:0] wr_ram_data,

    input  wire int_req,
    output wire int_ack
);
    bit [31:0] timestamp_counter;
    bit [INSTRUCTION_POINTER_BITS-1:0] pc;
    bit [INSTRUCTION_POINTER_BITS-1:0] isr_saved_pc;
    bit [15:0] ir;
    bit carry_flag;
    bit zero_flag;
    logic rd_mem_en;
    logic [MEMORY_ADDRESS_BITS-1:0] rd_mem_addr;
    logic mem_wr_en;
    logic [MEMORY_DATA_BITS-1:0] wr_mem_data;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_mem_addr;
    bit mem_wr_in_progress;
    ExecutionStage state;
    logic subtract;
    logic alu_carry;
    logic alu_zero;
    wire alu_zero_wire;
    wire [REGISTER_DATA_BITS-1:0] alu_input_b;
    wire [REGISTER_DATA_BITS-1:0] alu_output;
    wire [REGISTER_DATA_BITS-1:0] register_file_input;
    wire [REGISTER_DATA_BITS-1:0] regfile_rd0_data;
    wire [REGISTER_DATA_BITS-1:0] regfile_rd1_data;
    bit [REGISTER_DATA_BITS-1:0] inst_immediate;
    bit [REGISTER_DATA_BITS-1:0] load_mem;
    bit [3:0] reg_rd0_addr;
    bit [3:0] reg_rd1_addr;
    bit [3:0] reg_wr_addr;
    bit reg_rd0_en;
    bit reg_rd1_en;
    bit reg_wr_en;
    bit save_alu_flags;
    bit int_in_progress;
    bit prev_int_req;
    enum bit {IMMEDIATE, REGISTER_FILE} alu_inputB_sel;
    typedef enum bit[1:0] {ALU_OUTPUT = 0,
                           INST_IMMEDIATE = 1,
                           MEM_LOAD = 2,
                           REG_FILE_RD0 = 3} RegisterInputSelection;
    RegisterInputSelection reg_input_sel;

    assign rd_ram_en = rd_mem_en;
    assign wr_ram_en = mem_wr_en;
    assign rd_ram_addr = rd_mem_addr;
    assign wr_ram_addr = wr_mem_addr;
    assign wr_ram_data = mem_wr_in_progress ? wr_mem_data : {DATA_BITS{1'bz}}; // To drive the inout net

    alu #(.DATA_BITS(REGISTER_DATA_BITS))
        arith_unit(.clk(clk),
                   .reset_n(reset_n),
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

    register_file #(.DATA_BITS(REGISTER_DATA_BITS))
        registers(.clk(clk),
                  .reset_n(reset_n),

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

    // Mostly to show in waves what the current instruction is
    OpCode current_inst;

    logic instr_is_movir, instr_is_load, instr_is_store, instr_is_addrr, instr_is_addi,
          instr_is_subrr, instr_is_subi, instr_is_jnzi, instr_is_jzr, instr_is_jmp,
          int_is_cli, instr_is_sti, instr_is_reti, instr_is_nop;

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
    assign instr_is_jmp   =  ir[15] & ~ir[14] &  ir[13] & ~ir[12];
    assign instr_is_cli   =  ir[15] & ~ir[14] &  ir[13] &  ir[12];
    assign instr_is_sti   =  ir[15] &  ir[14] & ~ir[13] & ~ir[12];
    assign instr_is_reti  =  ir[15] &  ir[14] & ~ir[13] &  ir[12];
    assign instr_is_nop   =  ir[15] &  ir[14] &  ir[13] &  ir[12];

    assign instr_arithmetic = instr_is_addrr | instr_is_addi |
                              instr_is_subrr | instr_is_subi;
    assign subtract = (state == EXECUTE) && (instr_is_subrr | instr_is_subi);

    assign rd_mem_en = (state == FETCH_END) | (state == REGISTER_FETCH);// | ((state == EXECUTE) && instr_is_load);

    assign reg_rd0_en = instr_is_store |
                        instr_is_addrr | instr_is_addi |
                        instr_is_subrr | instr_is_subi;
    assign reg_rd1_en = instr_is_addrr | instr_is_subrr;

    assign reg_wr_en = ((state ==     EXECUTE) &&  instr_is_movir) |
                       ((state == REGISTER_WB) && (instr_is_load |
                                                   instr_is_addrr | instr_is_addi |
                                                   instr_is_subrr | instr_is_subi));
    assign reg_input_sel = ((state == REGISTER_WB) &&  instr_is_load) ? MEM_LOAD :
                          (((state ==     EXECUTE) && instr_is_movir) ? INST_IMMEDIATE :
                                                                       ALU_OUTPUT);

    assign alu_inputB_sel = (instr_is_addi || instr_is_subi ) && (state == EXECUTE)?
        IMMEDIATE :
        REGISTER_FILE;
    assign alu_zero = alu_zero_wire;

    function void request_register_reads;
        case (ir[15:12])
            MOVIR: begin
                reg_wr_addr    <= ir[11:8];
                inst_immediate <= rd_ram_data[7:0];
            end
            LOAD: begin
                reg_wr_addr    <= ir[11:8];
                // Prepare next transaction
                rd_mem_addr    <= rd_ram_data[7:0];
            end
            STORE: begin
                reg_rd0_addr   <= ir[11:8];
            end
            ADDRR: begin
                reg_rd0_addr   <= rd_ram_data[7:4];
                reg_rd1_addr   <= rd_ram_data[3:0];
                reg_wr_addr    <= ir[10:8];
            end
            ADDI: begin
                reg_rd0_addr   <= ir[11:8];
                reg_wr_addr    <= ir[11:8];
                inst_immediate <= rd_ram_data[7:0];
            end
            SUBRR: begin
                reg_rd0_addr   <= rd_ram_data[7:4];
                reg_rd1_addr   <= rd_ram_data[3:0];
                reg_wr_addr    <= ir[10:8];
            end
            SUBI: begin
                reg_rd0_addr   <= ir[11:8];
                reg_wr_addr    <= ir[11:8];
                inst_immediate <= rd_ram_data[7:0];
            end
            JNZI: begin
            end
            JZR: begin
            end
            JMP: begin
            end
            CLI: begin
            end
            STI: begin
            end
            RETI: begin
            end
            NOP: begin
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase
    endfunction

    function void execute_instruction;

        case (ir[15:12])
            MOVIR: begin
                $display("mov r%0d #%h", ir[11:8], ir[7:0]);
            end
            LOAD: begin
                $display("load r%0d @0x%02h", ir[11:8], ir[7:0]);
                load_mem  <= rd_ram_data;
            end
            STORE: begin
                $display("store @0x%02h r%0d", ir[7:0], ir[11:8]);
                // Launch memory write
                wr_mem_addr        <= ir[7:0];
                wr_mem_data        <= regfile_rd0_data;
                mem_wr_in_progress <= 1;
                mem_wr_en          <= 1;
            end
            ADDRR: begin
                $display("add r%0d r%0d r%0d", ir[11:8], ir[7:4], ir[3:0]);
            end
            ADDI: begin
                $display("add r%0d #0x%02h", ir[11:8], ir[7:0]);
            end
            SUBRR: begin
                $display("sub r%0d r%0d r%0d", ir[11:8], ir[7:4], ir[3:0]);
            end
            SUBI: begin
                $display("sub r%0d #0x%02h", ir[11:8], ir[7:0]);
            end
            JNZI: begin
                $display("jnz @0x%02h", ir[7:0]);
            end
            JZR: begin
                $display("jz reg");
            end
            JMP: begin
                $display("jmp reg:reg");
            end
            CLI: begin
                $display("cli");
            end
            STI: begin
                $display("sti");
            end
            RETI: begin
                $display("reti");
            end
            NOP: begin
                $display("nop");
            end
          default: $display("Invalid opcode %b", ir[15:12]);
        endcase

    endfunction

    typedef enum bit [1:0] {
        INT_IDLE,
        INT_REQUESTED,
        INT_SAVE_PC,
        INT_JUMP_ISR
    } InterruptStage;

    InterruptStage int_state;

    enum bit [2:0] {
        RESET            = 0,
        NEXT_INSTRUCTION = 1,
        JUMP_TARGET      = 2,
        NO_UPDATE        = 3,
        ISR_TARGET       = 4,
        ISR_RETURN       = 5,
        RESERVED_        = 6,
        RESERVED__       = 7
    } pc_offset_sel;
    wire [INSTRUCTION_POINTER_BITS-1:0] next_pc_input;
    bit [INSTRUCTION_POINTER_BITS-1:0] jump_dest;

    mux8to1 #(.DATA_BITS(INSTRUCTION_POINTER_BITS))
        pc_offset_mux(.sel(pc_offset_sel),
                      .in0('0),
                      .in1(INSTRUCTION_POINTER_BITS'(pc + 2)),
                      .in2(jump_dest),
                      .in3(pc),
                      .in4(constants_pkg::ISR_ADDRESS),
                      .in5(isr_saved_pc),
                      .in6({INSTRUCTION_POINTER_BITS'('b1)}),
                      .in7({INSTRUCTION_POINTER_BITS'('b1)}),
                      .out(next_pc_input));

    always @(posedge clk) begin
        if (!reset_n) begin
            timestamp_counter  <= 0;
            pc  <= 0;
        end else begin
            timestamp_counter++;
            pc  <= (int_state == INT_JUMP_ISR)?
                    ISR_ADDRESS :
                    next_pc_input;
        end
    end

    always @(posedge clk) begin
        if (!reset_n) begin
            $display("RESET");
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
            int_state          <= INT_IDLE;
            current_inst       <= NOP;
            jump_dest          <= 0;
            int_in_progress    <= 0;
            prev_int_req       <= 0;
        end else if (int_req && !prev_int_req) begin
            int_in_progress    <= 1;
            prev_int_req       <= int_req;
            int_state          <= INT_REQUESTED;
        end else begin
            if (int_state == INT_JUMP_ISR) begin
                isr_saved_pc <= next_pc_input;
                int_state    <= INT_JUMP_ISR;
            end
            prev_int_req <= int_req;
            case (state)
                FETCH_START: begin
                    // save ALU flags from previous instruction if necessary
                    zero_flag     <= save_alu_flags ? alu_zero : zero_flag;
                    carry_flag    <= save_alu_flags ? alu_carry : carry_flag;
                    // Prepare read transaction
                    rd_mem_addr   <= pc;
                    mem_wr_en     <= 0;
                    state         <= FETCH_END;
                end
                FETCH_END: begin
                    // Now read the data from the completed read transaction
                    ir[15:8]      <= rd_ram_data;
                    current_inst  <= OpCode'(rd_ram_data[7:4]);
                    // And prepare next transaction
                    rd_mem_addr   <= pc + 1;
                    state         <= REGISTER_FETCH;
                end
                REGISTER_FETCH: begin
                    // Read the second half of the instruction
                    ir[7:0]       <= rd_ram_data;
                    // Need to compute the jump target early, otherwise the instruction
                    // right after the jnz is executed before branching
                    jump_dest     <= rd_ram_data;
                    pc_offset_sel <= (int_state == INT_JUMP_ISR)?
                        ISR_TARGET :
                        ((ir[15:12] == RETI)?
                            ISR_RETURN :
                            ((instr_is_jnzi & ~zero_flag) ?
                                JUMP_TARGET :
                                NEXT_INSTRUCTION));
                    if (int_state == INT_REQUESTED) begin
                        int_state <= INT_JUMP_ISR;
                    end
                    request_register_reads();
                    state         <= EXECUTE;
                end
                EXECUTE: begin
                    // Program counter updates happened in the previous stage
                    // No updates until next instruction
                    pc_offset_sel <= NO_UPDATE;
                    execute_instruction();
                    save_alu_flags <= instr_arithmetic;

                    if (instr_arithmetic || instr_is_load)
                        state      <= REGISTER_WB;
                    else if (ir[15:12] == STORE)
                        state      <= STORE_STAGE;
                    else
                        state      <= FETCH_START;

                    if (int_state == INT_JUMP_ISR) begin
                        int_state <= INT_IDLE;
                    end
                end
                REGISTER_WB: begin
                    state          <= FETCH_START;
                end
                STORE_STAGE: begin
                    mem_wr_en          <= 0;
                    mem_wr_in_progress <= 0;
                    state              <= FETCH_START;
                end
                IDLE: begin
                    state <= FETCH_START;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
`endif
