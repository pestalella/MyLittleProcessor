`ifndef CONSTANTS_PKG_SV
`define CONSTANTS_PKG_SV

`timescale 1ns / 1ps

package constants_pkg;
    typedef enum bit [1:0] {REG_READ, REG_WRITE, ADD, SUB} ALUOp;
    typedef enum bit [2:0] {IDLE, INSTR_FETCH_START, INSTR_FETCH_END, REGISTER_FETCH,
                            EXECUTE, REGISTER_WB, LOAD_STAGE, STORE_STAGE} ExecutionStage;
    parameter int REGISTER_ADDRESS_BITS = 3;
    parameter int REGISTER_DATA_BITS = 8;
    parameter int MEMORY_ADDRESS_BITS = 8;
    parameter int MEMORY_DATA_BITS = 8;
    parameter int INSTRUCTION_POINTER_BITS = MEMORY_ADDRESS_BITS;
    parameter int JUMP_OFFSET_BITS = 8;

endpackage

`endif