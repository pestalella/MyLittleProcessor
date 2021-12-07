`ifndef ISA_DEFINITION_SV
`define ISA_DEFINITION_SV

package isa_pkg;
    typedef enum logic [3:0] {
        MOVIR = 4'b0000,
        LOAD  = 4'b0010,
        STORE = 4'b0011,
        ADDRR = 4'b0100,
        ADDI  = 4'b0101,
        SUBRR = 4'b0110,
        SUBI  = 4'b0111,
        JNZI  = 4'b1000,
        JZR   = 4'b1001,
        JMP   = 4'b1010,
        CLI   = 4'b1011,
        STI   = 4'b1100,
        RETI  = 4'b1101,
        NOP   = 4'b1111
    } OpCode;
endpackage


`endif
