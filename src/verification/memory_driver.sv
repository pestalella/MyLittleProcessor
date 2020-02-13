`ifndef MEMORY_DRIVER_SV
`define MEMORY_DRIVER_SV

`include "isa_definition.sv"
`include "memory_if.sv"
`include "regfile_trans.sv"

import isa_pkg::*;

class instruction;
    rand OpCode opcode;
    rand bit [3:0] dest_reg;
    rand bit [3:0] a_reg;
    rand bit [3:0] b_reg;
    rand bit [7:0] value;
    int id;

    constraint limited_isa  {opcode inside {MOVIR, JNZI, ADDRR, SUBRR, LOAD};};
//    constraint limited_isa  {opcode inside {MOVIR, ADDRR};};
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

class memory_driver;
    bit test_finished;
    int counter = 0;
    bit arith_zero;

    instruction random_instruction;
    bit [15:0] injected_instruction;
    bit [7:0] jump_dest;
    bit [7:0] program_counter;
    bit expect_jump;
    int jump_id;

    instruction instr_mem [0:255];
    bit [7:0] memory [0:255];

    virtual memory_if vif;
    mailbox #(regfile_trans) drv2scb;
    bit instr_generated;

    function new (virtual memory_if.mem_mon vif, mailbox #(regfile_trans) drv2scb);
        this.vif = vif;
        this.drv2scb = drv2scb;
        this.test_finished = 0;
        this.random_instruction = new();
        this.random_instruction.srandom(42);
        this.instr_generated = 0;
        this.program_counter = 0;
        this.expect_jump = 0;
    endfunction

    task fill_memory;
        bit [15:0] encoded;
        for (int i = 0; i < 256; i+=2) begin
            random_instruction.randomize();
            instr_mem[i >> 1] = random_instruction.copy();
            encoded = random_instruction.encoded();
            memory[i + 0] = encoded[15:8];
            memory[i + 1] = encoded[7:0];
        end
    endtask

    task send_instruction_to_scoreboard(instruction instr);
        regfile_trans trans;

        if (instr.opcode == LOAD) begin
            // Inject a NOP to wait for the load result to be loaded into a register
            trans = new();
            trans.action =regfile_trans::NOP;
            drv2scb.put(trans);
        end

        trans = new();
        trans.action = instr.opcode == MOVIR ? regfile_trans::WRITE :
                      (instr.opcode ==  LOAD ? regfile_trans::WRITE :
                      (instr.opcode == ADDRR ? regfile_trans::ADD :
                      (instr.opcode == SUBRR ? regfile_trans::SUB :
                      (instr.opcode ==  JNZI ? regfile_trans::JUMP :
                                               regfile_trans::NOP))));

        trans.dest_reg = instr.dest_reg;
        trans.a_reg = instr.a_reg;
        trans.b_reg = instr.b_reg;
        trans.value = instr.opcode == LOAD ? memory[instr.value] : instr.value;
        drv2scb.put(trans);
    endtask;

    task inject_instructions;
        regfile_trans trans;
        instruction cur_instr;
        bit instr_begin = 1;

        forever begin
            @(vif.rd_addr or vif.rd_en) begin
                if (test_finished) begin
                    vif.rd_data <= {NOP, 4'b0000};
                end else begin
                    if (vif.rd_en) begin
                        // $display("[%6dns] MEM_DRV add @0x%02h injected byte: 0x%02h", $time,
                        //     vif.rd_addr, memory[vif.rd_addr]);
                        vif.rd_data <= memory[vif.rd_addr];

                        if (instr_begin)
                            program_counter = vif.rd_addr;

                        if (instr_begin) begin
                            cur_instr = instr_mem[vif.rd_addr >> 1];
                            send_instruction_to_scoreboard(cur_instr);
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

    task run;
        fill_memory();
        fork
            inject_instructions();
        join_any

    endtask
endclass

`endif