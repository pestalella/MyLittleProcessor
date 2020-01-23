
`include "constants_pkg.sv"
`include "execution_unit.sv"
`include "isa_definition.sv"
`include "memory_driver.sv"
`include "memory_if.sv"
`include "regfile_if.sv"
`include "regfile_mon.sv"
`include "regfile_sb.sv"

import constants_pkg::*;
import isa_pkg::*;

module eu_state_change_monitor (
    input ExecutionStage state,
    output logic new_instruction);

    always @(state) begin
//        $display("EU_STATE_MON [%0dns]: state changed to %s", $time, state.name);
        if (state == FETCH_MSB_IR)
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

    regfile_if vif();

    assign vif.clk = clk;
    assign vif.reset = reset;
    assign vif.wr_addr = wr_addr;
    assign vif.wr_enable = wr_enable;
    assign vif.wr_data = wr_data;

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
    assign new_instruction_wire = dut.state_mon.new_instruction;

    always begin
        #5 clk = ~clk;
    end

    task reset_dut(mailbox drv2scb);
        regfile_trans trans = new();
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

    always_ff @(posedge new_instruction_wire) begin
        mem_drv.new_instruction();
    end

    initial begin
        mailbox mon2scb;
        mailbox drv2scb;
        regfile_mon rf_mon;

        mon2scb = new();
        drv2scb = new();
        mem_drv = new(mem_if, drv2scb);
        rf_mon = new(dut.registers.rf_probe.vif, mon2scb);
        rf_sb = new(drv2scb, mon2scb);

        fork
            reset_dut(drv2scb);
            rf_mon.run();
            rf_sb.run();
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