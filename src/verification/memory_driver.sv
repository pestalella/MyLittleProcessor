`ifndef MEMORY_DRIVER_SV
`define MEMORY_DRIVER_SV

`include "instruction.sv"

import isa_pkg::*;

class memory_driver;
    logic test_finished;
    int counter = 0;
    logic arith_zero;

    instruction random_instruction;
    logic [15:0] injected_instruction;
    logic [7:0] jump_dest;
    logic [7:0] program_counter;
    logic expect_jump;
    int jump_id;

    instruction instr_mem [0:255];
    logic [7:0] memory [0:255];

    virtual memory_if vif;
    mailbox #(regfile_trans) drv2scb;
    logic instr_generated;

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
        logic [15:0] encoded;
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
        trans.action = instr.opcode == MOVIR ? regfile_trans::REG_WRITE :
                      (instr.opcode ==  LOAD ? regfile_trans::REG_WRITE :
                      (instr.opcode == ADDRR ? regfile_trans::ADD :
                      (instr.opcode == SUBRR ? regfile_trans::SUB :
                                               regfile_trans::NOP)));

        trans.dest_reg = instr.dest_reg;
        trans.a_reg = instr.a_reg;
        trans.b_reg = instr.b_reg;
        trans.value = instr.opcode == LOAD ? memory[instr.value] : instr.value;
        drv2scb.put(trans);
    endtask;

    task track_memory_writes;
        forever begin
            @(vif.wr_addr or vif.wr_en) begin
                if (vif.wr_en)
                    $display("[%6dns] MEM_DRV captured a memory write addr:@0x%02h val: 0x%02h", $time, vif.wr_addr, vif.wr_data);
            end
        end
    endtask

    task inject_instructions;
        regfile_trans trans;
        instruction cur_instr;
        logic instr_begin = 1;

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
            track_memory_writes();
        join_any

    endtask
endclass

`endif
