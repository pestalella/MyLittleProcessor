`ifndef MEMORY_DRIVER_SV
`define MEMORY_DRIVER_SV

`include "memory_if.sv"
`include "regfile_trans.sv"

class memory_driver;
    bit test_finished;
    int counter = 0;
    bit [15:0] injected_instruction;

    virtual memory_if vif;
    mailbox drv2scb;

    function new (virtual memory_if.mem_mon vif, mailbox drv2scb);
        this.vif = vif;
        this.drv2scb = drv2scb;
        this.test_finished = 0;
    endfunction

    function bit[15:0] random_mov;
        bit [3:0] opcode = MOVIR;
        bit [2:0] dest_reg = $urandom;
        bit [7:0] value = $urandom;
        $display("MEM_DRV [%0dns] instr_generator: new instruction MOV r%0d, #%02h", $time, dest_reg, value);
        return {{opcode, {1'b0, dest_reg}}, value};
    endfunction

    task inject_instructions;
        bit instr_begin = 0;

        forever begin
            @(vif.rd_addr) begin
                $display("MEM_DRV [%0dns] rd_en:%0d addr:%02h", $time, vif.rd_en, vif.rd_addr);
                vif.rd_data <= test_finished? {NOP, 4'b0000} :
                              (vif.rd_en? (vif.rd_addr[0] ? injected_instruction[7:0] : injected_instruction[15:8]) :
                                           vif.rd_data);
            end
        end
    endtask

    task new_instruction;
        regfile_trans trans;

        counter += 1;
        if (counter >= 6) begin
            $display("MEM_DRV [%0dns]: Test finished", $time);
            test_finished = 1;
        end else begin
            injected_instruction = random_mov();
            trans = new();
            trans.action = regfile_trans::WRITE;
            trans.register = injected_instruction[10:8];
            trans.value = injected_instruction[7:0];
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