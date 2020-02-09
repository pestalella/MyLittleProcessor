`include "constants_pkg.sv"
`include "execution_unit.sv"
`include "isa_definition.sv"
`include "memory_bus_checker.sv"
`include "memory_driver.sv"
`include "memory_if.sv"
`include "regfile_if.sv"
`include "regfile_mon.sv"
`include "regfile_sb.sv"
`include "regfile_trans.sv"

import constants_pkg::*;
import isa_pkg::*;

module eu_state_change_monitor (
    input ExecutionStage state,
    output logic new_instruction);

    always @(state) begin
        if (state == INSTR_FETCH_START)
            new_instruction <= 1;
        else
            new_instruction <= 0;
    end
endmodule

module regfile_probe(
    input wire clk,
    input wire reset,
    input wire [REGISTER_ADDRESS_BITS-1:0] wr_addr,
    input wire wr_enable,
    input wire [REGISTER_DATA_BITS-1:0] wr_data);

    regfile_if rvif();

    assign rvif.clk = clk;
    assign rvif.reset = reset;
    assign rvif.wr_addr = wr_addr;
    assign rvif.wr_enable = wr_enable;
    assign rvif.wr_data = wr_data;
endmodule


module reg_bits_probe(
    input wire clk,
    input wire [REGISTER_DATA_BITS-1:0] r0,
    input wire [REGISTER_DATA_BITS-1:0] r1,
    input wire [REGISTER_DATA_BITS-1:0] r2,
    input wire [REGISTER_DATA_BITS-1:0] r3,
    input wire [REGISTER_DATA_BITS-1:0] r4,
    input wire [REGISTER_DATA_BITS-1:0] r5,
    input wire [REGISTER_DATA_BITS-1:0] r6,
    input wire [REGISTER_DATA_BITS-1:0] r7);

    register_inspection_if reg_if();

    assign reg_if.clk = clk;
    assign reg_if.r0 = r0;
    assign reg_if.r1 = r1;
    assign reg_if.r2 = r2;
    assign reg_if.r3 = r3;
    assign reg_if.r4 = r4;
    assign reg_if.r5 = r5;
    assign reg_if.r6 = r6;
    assign reg_if.r7 = r7;
endmodule

module tb_exec_unit ();

    logic clk;
    logic reset;

    logic rd_ram_en;
    logic [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr;
    logic [MEMORY_DATA_BITS-1:0] rd_ram_data;

    logic wr_ram_en;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr;
    logic [MEMORY_DATA_BITS-1:0] wr_ram_data;

    wire new_instruction_wire;

    memory_if mem_if();

    exec_unit #(.DATA_BITS(8)) dut (
        .clk(clk),
        .reset(reset),

        .rd_ram_en(mem_if.rd_en),
        .rd_ram_addr(mem_if.rd_addr),
        .rd_ram_data(mem_if.rd_data),

        .wr_ram_en(mem_if.wr_en),
        .wr_ram_addr(mem_if.wr_addr),
        .wr_ram_data(mem_if.wr_data)
    );

    bind dut alu_if alu_zero_if(
        .dut_zero(alu_zero)
    );

    bind dut.registers regfile_probe rf_probe(
        .clk(clk),
        .reset(reset),

        .wr_addr(wr_addr),
        .wr_enable(wr_enable),
        .wr_data(wr_data));

    bind dut eu_state_change_monitor state_mon(
        .state(state),
        .new_instruction()
    );

    bind dut.registers reg_bits_probe regbits_probe(
        .clk(clk),
        .r0(regs[0].r.bits),
        .r1(regs[1].r.bits),
        .r2(regs[2].r.bits),
        .r3(regs[3].r.bits),
        .r4(regs[4].r.bits),
        .r5(regs[5].r.bits),
        .r6(regs[6].r.bits),
        .r7(regs[7].r.bits)
    );

    assign new_instruction_wire = dut.state_mon.new_instruction;

    always begin
        #5 clk = ~clk;
    end

    task reset_dut(mailbox #(regfile_trans) drv2scb);
        regfile_trans trans;
        trans = new();
        trans.action = regfile_trans::RESET;
        drv2scb.put(trans);

        clk = 0;
        // reset the DUT
        reset = 1;
        @(posedge clk)
            #5 reset = 0;
    endtask

    regfile_sb rf_sb;
    memory_driver mem_drv;

    // always_ff @(posedge new_instruction_wire) begin
    //     mem_drv.new_instruction();
    // end

    initial begin
        memory_bus_checker memb_chk;
        mailbox mon2scb;
        mailbox #(regfile_trans) drv2scb;
        regfile_mon rf_mon;

        mon2scb = new();
        drv2scb = new();
        mem_drv = new(mem_if, drv2scb);
        memb_chk = new(mem_if, dut.alu_zero_if);
        rf_mon = new(dut.registers.rf_probe.rvif, mon2scb);
        rf_sb = new(drv2scb, mon2scb, dut.registers.regbits_probe.reg_if);

        fork
            reset_dut(drv2scb);
            rf_mon.run();
            rf_sb.run();
            memb_chk.run();
            mem_drv.run();
        join_any
    end

    always @(posedge clk) begin
        if (mem_drv.test_finished) begin
            rf_sb.stop();
            $finish();
        end
    end

endmodule