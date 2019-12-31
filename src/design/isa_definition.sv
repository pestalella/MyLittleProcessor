`ifndef ISA_DEFINITION_SV
`define ISA_DEFINITION_SV

package isa_pkg;
    typedef enum bit [3:0] {
        MOVIR = 4'b0000,
        MOVRR = 4'b0001,
        MOVMR = 4'b0010,
        MOVRM = 4'b0011,
        ADDRR = 4'b0100,
        ADDI  = 4'b0101,
        SUBRR = 4'b0110,
        SUBI  = 4'b0111,
        JZI   = 4'b1000,
        JZR   = 4'b1001,
        NOP   = 4'b1111
    } OpCode;
endpackage


`endif