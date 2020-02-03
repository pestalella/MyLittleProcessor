`ifndef REGFILE_TRANS_SV
`define REGFILE_TRANS_SV

class regfile_trans;
    typedef enum {RESET, WRITE, ADD, SUB, ADDI, SUBI, NOP, JUMP, CHECK_JUMP} RegfileAction;
    RegfileAction action;
    int dest_reg;
    int a_reg;
    int b_reg;
    int value;
    bit [7:0] next_instr_address;
    bit [7:0] jump_dest;
endclass

`endif