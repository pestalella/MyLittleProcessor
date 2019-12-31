`ifndef CONSTANTS_PKG_SV
`define CONSTANTS_PKG_SV

`timescale 1ns / 1ps

package constants_pkg;
    typedef enum bit [1:0] {REG_READ, REG_WRITE, ADD, SUB} ALUOp;
    parameter int MEMORY_ADDRESS_BITS = 8;
    parameter int MEMORY_DATA_BITS = 8;
    parameter int INSTRUCTION_POINTER_BITS = MEMORY_ADDRESS_BITS;

endpackage

`endif