`ifndef MEMORY_DRIVER_SV
`define MEMORY_DRIVER_SV

`include "isa_definition.sv"
`include "memory_if.sv"
`include "regfile_trans.sv"

import isa_pkg::*;

class Instruction;
    rand OpCode opcode;
    rand bit [3:0] dest_reg;
    rand bit [3:0] a_reg;
    rand bit [3:0] b_reg;
    rand bit [7:0] value;

    constraint limited_isa  {opcode inside {MOVIR, JNZI, ADDRR, SUBRR};};
    constraint limited_regs {dest_reg inside {[0:7]};
                                a_reg inside {[0:7]};
                                b_reg inside {[0:7]};};

    function bit[15:0] encoded;
        case (this.opcode)
            MOVIR: begin
                return {opcode, dest_reg, value};
            end
            LOAD: begin
                return '0;
            end
            STORE: begin
                return '0;
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
                return $sformatf("mov r%0d #%h", this.dest_reg, this.value);
            end
            LOAD: begin
                return $sformatf("load r%0d @%h", this.dest_reg, this.value);
            end
            STORE: begin
                return $sformatf("store @%h r%0d", this.value, this.dest_reg);
            end
            ADDRR: begin
                return $sformatf("add r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             ADDI: begin
                return $sformatf("add r%0d #%h", this.dest_reg, this.value);
            end
            SUBRR: begin
                return $sformatf("sub r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             SUBI: begin
                return $sformatf("sub r%0d #%h", this.dest_reg, this.value);
            end
             JNZI: begin
                return $sformatf("jnz @%0d", this.value);
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

class memory_driver;
    bit test_finished;
    int counter = 0;
    bit arith_zero;

    Instruction random_instruction;
    bit [15:0] injected_instruction;
    bit [7:0] jump_dest;
    bit [7:0] no_jump_dest;

    virtual memory_if vif;
    mailbox #(regfile_trans) drv2scb;

    function new (virtual memory_if.mem_mon vif, mailbox #(regfile_trans) drv2scb);
        this.vif = vif;
        this.drv2scb = drv2scb;
        this.test_finished = 0;
        this.random_instruction = new();
        this.random_instruction.srandom(1);
    endfunction

    function generate_instruction;
        if (counter < 8) begin
            random_instruction.opcode = MOVIR;
            random_instruction.dest_reg = counter;
            random_instruction.value = {4'(counter+1), 4'(counter+1)};
        end else begin
            random_instruction.randomize();
        end
        injected_instruction = random_instruction.encoded();
        $display("[%0dns] MEM_DRV instr_generator: new instruction [%s]", $time, random_instruction.toString());
    endfunction

    task inject_instructions;
        regfile_trans trans;
        bit instr_begin = 0;
        bit expect_jump = 0;

        forever begin
            @(vif.rd_addr or vif.rd_en) begin
                if (test_finished) begin
                    vif.rd_data <= {NOP, 4'b0000};
                end else begin
                    if (expect_jump) begin
                        trans = new();
                        trans.action = regfile_trans::CHECK_JUMP;
                        trans.jump_dest = vif.rd_addr;
                        drv2scb.put(trans); 
                    end

                    vif.rd_data <= vif.rd_en? (instr_begin ? injected_instruction[7:0] : 
                                                             injected_instruction[15:8]) :
                                               vif.rd_data;

                    if (~instr_begin & random_instruction.opcode == JNZI) begin
                        trans = new();
                        trans.action = regfile_trans::JUMP;
                        trans.jump_dest = random_instruction.value;
                        trans.next_instr_address = vif.rd_addr + 1;
                        drv2scb.put(trans); 
                        expect_jump = 1;
                    end else begin
                        expect_jump = 0;
                    end
                end
                instr_begin = vif.rd_en? ~instr_begin : instr_begin;
            end
        end
    endtask

    task new_instruction;
        regfile_trans trans;

        if (counter > 1000) begin
            $display("[%0dns] MEM_DRV: Test finished", $time);
            test_finished = 1;
        end else begin
            generate_instruction();
            trans = new();
            trans.action = random_instruction.opcode == MOVIR ? regfile_trans::WRITE :
                          (random_instruction.opcode == ADDRR ? regfile_trans::ADD :
                          (random_instruction.opcode == SUBRR ? regfile_trans::SUB :
                          regfile_trans::NOP));
            trans.dest_reg = random_instruction.dest_reg;
            trans.a_reg = random_instruction.a_reg;
            trans.b_reg = random_instruction.b_reg;
            trans.value = random_instruction.value;
            drv2scb.put(trans);
        end
        counter += 1;
    endtask

    task run;
        fork
            inject_instructions();
        join_any

    endtask
endclass

`endif