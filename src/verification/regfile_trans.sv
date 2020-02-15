`ifndef REGFILE_TRANS_SV
`define REGFILE_TRANS_SV

class regfile_trans;
    typedef enum {RESET, REG_WRITE, ADD, SUB, ADDI, SUBI, NOP} RegfileAction;
    RegfileAction action;
    int dest_reg;
    int a_reg;
    int b_reg;
    int value;
endclass

`endif