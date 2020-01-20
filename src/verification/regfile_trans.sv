`ifndef REGFILE_TRANS_SV
`define REGFILE_TRANS_SV

class regfile_trans;
    typedef enum {RESET, WRITE} RegfileAction;
    RegfileAction action;
    int register;
    int value;
endclass

`endif