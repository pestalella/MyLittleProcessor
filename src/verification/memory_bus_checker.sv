`ifndef MEMORY_BUS_CHECKER_SV
`define MEMORY_BUS_CHECKER_SV

`include "alu_if.sv"
`include "isa_definition.sv"
`include "memory_if.sv"

import isa_pkg::*;

// This checker snoops on the memory interface and decodes the instructions
// in flight. The sets the next expected read address according to the
// decoded instruction. If the instruction is not a JNZ, the next memory
// access (barring LOADs, need tro add support for them) should be the
// start address of the current instruction + 1. If it's a jump, it checks
// the value of the ZERO bit in the execution unit and decides whether the
// jump will be taken or not. If taken, set the next expected read address
// to the jump target.

class memory_bus_checker;
    virtual memory_if mem_vif;
    virtual alu_if alu_vif;

    function new(virtual memory_if mem_vif, virtual alu_if alu_vif);
        this.mem_vif = mem_vif;
        this.alu_vif = alu_vif;
    endfunction;

    task run;
        OpCode opcode;
        bit instr_start;
        bit expect_load;
        bit [7:0] next_instr_addr;
        bit [7:0] next_load_addr;

        expect_load = 0;
        instr_start = 1;
        next_instr_addr = 0;

        forever begin
            @(mem_vif.rd_en or mem_vif.rd_addr) begin
                if (mem_vif.rd_en) begin
                    #1 $write("[%6dns] membus_chk: read addr @0x%02h", $time, mem_vif.rd_addr);

                    if (expect_load) begin
                        assert (next_load_addr == mem_vif.rd_addr)
                            $display(" as expected.");
                        else
                            $error("Unexpected load address. actual:0x%02h  expected:0x%02h",
                                    mem_vif.rd_addr, next_load_addr);

                        expect_load = 0;
                    end else begin
                        // Not expecting a load, mem read should be a instruction
                        assert (next_instr_addr == mem_vif.rd_addr)
                        else $error("Unexpected instruction address. actual:0x%02h  expected:0x%02h",
                                    mem_vif.rd_addr, next_instr_addr);

                        next_instr_addr = next_instr_addr + 1;

                        if (instr_start) begin
                            opcode = OpCode'(mem_vif.rd_data[7:4]);
                            $display(" data @0x%02h  opcode: %s", mem_vif.rd_data, opcode.name);
                        end else begin
                            $display(" data @0x%02h", mem_vif.rd_data);
                            if (opcode == JNZI && ~alu_vif.zero) begin
                                next_instr_addr = mem_vif.rd_data;
                            end else if (opcode == LOAD) begin
                                next_load_addr = mem_vif.rd_data;
                                expect_load = 1;
                                $display("[%6dns] membus_chk: expect load from addr @0x%02h", $time, next_load_addr);
                            end
                        end
                    end
                    if (~expect_load)
                        instr_start = ~instr_start;
                end
            end
        end
    endtask
endclass

`endif