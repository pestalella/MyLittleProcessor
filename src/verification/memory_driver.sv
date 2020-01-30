`ifndef MEMORY_DRIVER_SV
`define MEMORY_DRIVER_SV

`include "isa_definition.sv"
`include "memory_if.sv"
`include "regfile_trans.sv"

import isa_pkg::*;

class Instruction;
    rand OpCode opcode;
    rand bit [2:0] dest_reg;
    rand bit [7:0] value;

    constraint limited_isa {opcode inside {MOVIR, JNZI};};
endclass

class memory_driver;
    bit test_finished;
    int counter = 0;

    Instruction random_instruction;
    bit [15:0] injected_instruction;

    virtual memory_if vif;
    mailbox drv2scb;

    function new (virtual memory_if.mem_mon vif, mailbox drv2scb);
        this.vif = vif;
        this.drv2scb = drv2scb;
        this.test_finished = 0;
        this.random_instruction = new();
    endfunction

    function generate_instruction;
        random_instruction.randomize();
        injected_instruction = {random_instruction.opcode, {1'b0, random_instruction.dest_reg}, random_instruction.value};

        $display("MEM_DRV [%0dns] instr_generator: new instruction %s r%0d, #%02h", $time,
            random_instruction.opcode.name, random_instruction.dest_reg, random_instruction.value);
    endfunction

    task inject_instructions;
        bit instr_begin = 0;

        forever begin
            @(vif.rd_addr or vif.rd_en) begin
                // $display("MEM_DRV [%0dns] rd_en:%0d addr:%02h  injected_byte:%02h", $time, vif.rd_en, vif.rd_addr,
                //      (vif.rd_en? (vif.rd_addr[0] ? injected_instruction[7:0] : injected_instruction[15:8]) :
                //                            vif.rd_data) );

                vif.rd_data <= test_finished? {NOP, 4'b0000} :
                              (vif.rd_en? (instr_begin ? injected_instruction[7:0] : injected_instruction[15:8]) :
                                           vif.rd_data);
                instr_begin = vif.rd_en? ~instr_begin : instr_begin;
            end
        end
    endtask

    task new_instruction;
        regfile_trans trans;

        counter += 1;
        if (counter >= 1000) begin
            $display("MEM_DRV [%0dns]: Test finished", $time);
            test_finished = 1;
        end else begin
            generate_instruction();
            trans = new();
            trans.action = random_instruction.opcode == MOVIR ? regfile_trans::WRITE : regfile_trans::NOP;
            trans.register = random_instruction.dest_reg;
            trans.value = random_instruction.value;
            drv2scb.put(trans);
//            $display("MEM_DRV [%0dns]: new instruction (%0d)", $time, counter);
        end
    endtask

    task run;
        fork
            inject_instructions();
        join_any

    endtask
endclass

`endif