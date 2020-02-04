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
    int id;

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
                return $sformatf("mov r%0d #%02h", this.dest_reg, this.value);
            end
            LOAD: begin
                return $sformatf("load r%0d @%02h", this.dest_reg, this.value);
            end
            STORE: begin
                return $sformatf("store @%02h r%0d", this.value, this.dest_reg);
            end
            ADDRR: begin
                return $sformatf("add r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             ADDI: begin
                return $sformatf("add r%0d #%02h", this.dest_reg, this.value);
            end
            SUBRR: begin
                return $sformatf("sub r%0d r%0d r%0d", this.dest_reg, this.a_reg, this.b_reg);
            end
             SUBI: begin
                return $sformatf("sub r%0d #%02h", this.dest_reg, this.value);
            end
             JNZI: begin
                return $sformatf("jnz @%02h", this.value);
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
    bit [7:0] program_counter;
    bit expect_jump;
    int jump_id;


    virtual memory_if vif;
    mailbox #(regfile_trans) drv2scb;
    bit instr_generated;

    function new (virtual memory_if.mem_mon vif, mailbox #(regfile_trans) drv2scb);
        this.vif = vif;
        this.drv2scb = drv2scb;
        this.test_finished = 0;
        this.random_instruction = new();
        this.random_instruction.srandom(1);
        this.instr_generated = 0;
        this.program_counter = 0;
        this.expect_jump = 0;
    endfunction

    function generate_instruction;
        if (counter < 8) begin
            random_instruction.opcode = MOVIR;
            random_instruction.dest_reg = counter;
            random_instruction.value = {4'(counter+1), 4'(counter+1)};
        end else if (counter == 8) begin
            random_instruction.opcode = SUBRR;
            random_instruction.dest_reg = 0;
            random_instruction.a_reg = 1;
            random_instruction.b_reg = 1;
        end else if (counter == 9) begin
            random_instruction.opcode = JNZI;
            random_instruction.value = 0;
        end else begin
            random_instruction.randomize();
        end
        injected_instruction = random_instruction.encoded();
        random_instruction.id = counter;
        instr_generated = 1;
        $display("[%0dns] MEM_DRV instr_generator: new instruction [%s]", $time, random_instruction.toString());
    endfunction

    task inject_instructions;
        regfile_trans trans;
        bit instr_begin = 1;

        forever begin
            @(vif.rd_addr or vif.rd_en) begin
                if (test_finished) begin
                    vif.rd_data <= {NOP, 4'b0000};
                end else begin
                    if (vif.rd_en) begin
                        vif.rd_data <= instr_begin ? injected_instruction[15:8] :
                                                     injected_instruction[7:0];

                        if (instr_begin) 
                            program_counter = vif.rd_addr;

                        if (instr_begin && expect_jump && (random_instruction.id == jump_id + 1)) begin
                            trans = new();
                            trans.action = regfile_trans::CHECK_JUMP;
                            trans.jump_dest = program_counter;
                            drv2scb.put(trans);
                            expect_jump = 0;
                        end

                        if (~instr_begin)
                            instr_generated = 0;

                        instr_begin = ~instr_begin;
                    end else begin
                        vif.rd_data <= vif.rd_data;
                    end
                end
            end
        end
    endtask

    task new_instruction;
        regfile_trans trans;

        wait (~instr_generated);

        if (counter > 1000) begin
            $display("[%0dns] MEM_DRV: Test finished", $time);
            test_finished = 1;
        end else begin
            generate_instruction();
            trans = new();
            trans.action = random_instruction.opcode == MOVIR ? regfile_trans::WRITE :
                          (random_instruction.opcode == ADDRR ? regfile_trans::ADD :
                          (random_instruction.opcode == SUBRR ? regfile_trans::SUB :
                          (random_instruction.opcode ==  JNZI ? regfile_trans::JUMP :
                          regfile_trans::NOP)));

            trans.dest_reg = random_instruction.dest_reg;
            trans.a_reg = random_instruction.a_reg;
            trans.b_reg = random_instruction.b_reg;
            trans.value = random_instruction.value;
            trans.jump_dest = random_instruction.value;
            trans.next_instr_address = program_counter + 4;
            drv2scb.put(trans);
            if (random_instruction.opcode == JNZI) begin
                expect_jump = 1;
                jump_id = random_instruction.id;
            end
            counter += 1;
        end
    endtask

    task run;
        fork
            inject_instructions();
        join_any

    endtask
endclass

`endif