`ifndef INSTRUCTION_SV
`define INSTRUCTION_SV

`include "isa_definition.sv"

import isa_pkg::*;

class instruction;
    rand OpCode opcode;
    rand bit [3:0] dest_reg;
    rand bit [3:0] a_reg;
    rand bit [3:0] b_reg;
    rand bit [7:0] value;
    int id;

    constraint limited_isa  {opcode inside {MOVIR, JNZI, ADDRR, SUBRR, LOAD};};
    constraint instr_alignment  {(opcode == JNZI) -> (value[0] == 0);};
    constraint limited_regs {dest_reg inside {[0:7]};
                                a_reg inside {[0:7]};
                                b_reg inside {[0:7]};};

    function instruction copy;
        copy = new();
        copy.opcode = this.opcode;
        copy.dest_reg = this.dest_reg;
        copy.a_reg = this.a_reg;
        copy.b_reg = this.b_reg;
        copy.value = this.value;
        copy.id = this.id;
        return copy;
    endfunction

    function bit[15:0] encoded;
        case (this.opcode)
            MOVIR: begin
                return {opcode, dest_reg, value};
            end
            LOAD: begin
                return {opcode, dest_reg, value};
            end
            STORE: begin
                return {opcode, dest_reg, value};
            end
            ADDRR: begin
                return {opcode, dest_reg, a_reg, b_reg};
            end
             ADDI: begin
                return {opcode, dest_reg, value};
            end
            SUBRR: begin
                return {opcode, dest_reg, a_reg, b_reg};
            end
             SUBI: begin
                return {opcode, dest_reg, value};
            end
             JNZI: begin
                return {opcode, 4'b0, value};
            end
              JZR: begin
                return '0;
            end
              NOP: begin
                return {opcode, 4'b0, 8'b0};
              end
        endcase

    endfunction

    function string toString;
        case (this.opcode)
            MOVIR: begin
                return $sformatf("mov r%0d #0x%02h", this.dest_reg, this.value);
            end
            LOAD: begin
                return $sformatf("load r%0d @0x%02h", this.dest_reg, this.value);
            end
            STORE: begin
                return $sformatf("store @0x%02h r%0d", this.value, this.dest_reg);
            end
            ADDRR: begin
                return $sformatf("add r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             ADDI: begin
                return $sformatf("add r%0d #0x%02h", this.dest_reg, this.value);
            end
            SUBRR: begin
                return $sformatf("sub r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             SUBI: begin
                return $sformatf("sub r%0d #0x%02h", this.dest_reg, this.value);
            end
             JNZI: begin
                return $sformatf("jnz @0x%02h", this.value);
            end
              JZR: begin
                return $sformatf("jz reg");
            end
              NOP: begin
                return $sformatf("nop");
              end
        endcase
    endfunction
endclass

`endif