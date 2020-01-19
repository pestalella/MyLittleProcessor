`include "constants_pkg.sv"
`include "execution_unit.sv"
`include "isa_definition.sv"
`include "regfile_if.sv"
`include "regfile_mon.sv"

import constants_pkg::*;
import isa_pkg::*;

module memory_mock (
    input wire clk,
    input wire new_instruction,
    input  wire rd_en,
    input  wire [MEMORY_ADDRESS_BITS-1:0] rd_addr,
    output wire [MEMORY_DATA_BITS-1:0] rd_data,
    input  wire wr_en,
    input  wire [MEMORY_ADDRESS_BITS-1:0] wr_addr,
    input  wire [MEMORY_DATA_BITS-1:0] wr_data);

    int counter = 0;
    logic [MEMORY_ADDRESS_BITS-1:0] prog_counter;

    bit [MEMORY_DATA_BITS-1:0] instr_stream[8] = {
        {NOP, 4'b0000}, 8'b0,
        {MOVIR, 4'b0000}, 8'b01010101,
        {MOVIR, 4'b0001}, 8'b10101010,
        {MOVIR, 4'b0010}, 8'b00010001
    };

    always @(posedge new_instruction) begin
        counter += 1;
        $display("MEMORY_MOCK [%0dns]: new instruction (%0d)", $time, counter);
    end

//    assign prog_counter = (counter*2 + rd_addr[0]) % 8;
    assign rd_data = instr_stream[rd_addr % 8];

//     always @(posedge clk or rd_en) begin
// //        rd_data <= rd_addr[0] ? '0 : {NOP, 4'b0000};
//         rd_data <= instr_stream[((counter-1)*2 + rd_addr[0]) % 8];
//     end
endmodule

module eu_state_change_monitor (
    input ExecutionStage state,
    output logic new_instruction);

    always @(state) begin
        $display("EU_STATE_MON [%0dns]: state changed to %s", $time, state.name);
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

    exec_unit #(.DATA_BITS(8)) dut (
        .clk(clk),
        .reset(reset),

        .rd_ram_en(rd_ram_en),
        .rd_ram_addr(rd_ram_addr),
        .rd_ram_data(rd_ram_data),

        .wr_ram_en(wr_ram_en),
        .wr_ram_addr(wr_ram_addr),
        .wr_ram_data(wr_ram_data)
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

    memory_mock fake_mem (
        .clk(clk),
        .new_instruction(new_instruction_wire),
        .rd_en(rd_ram_en),
        .rd_addr(rd_ram_addr),
        .rd_data(rd_ram_data),
        .wr_en(wr_ram_en),
        .wr_addr(wr_ram_addr),
        .wr_data(wr_ram_data)
    );

    always begin
        #5 clk = ~clk;
    end

    task reset_dut;
        clk = 0;
        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;
    endtask

    initial begin
        mailbox mon2scb;
        regfile_mon rf_mon;

        mon2scb = new();
        rf_mon = new(dut.registers.rf_probe.vif, mon2scb);

        fork
            reset_dut();
            rf_mon.run();
        join_any

    end

endmodule