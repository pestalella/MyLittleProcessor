`ifndef EXECUTION_UNIT_SV
`define EXECUTION_UNIT_SV

`timescale 1ns / 1ps

`include "register.sv"
`include "constants_pkg.sv"

import constants_pkg::*;

module exec_unit #(parameter DATA_BITS = 8) (
    input wire clk,
    input wire reset
);
    // register_bus #(.ADDR_BITS(ADDR_BITS),
    //                .DATA_BITS(DATA_BITS)) rd0_bus();
    // register_bus #(.ADDR_BITS(ADDR_BITS),
    //                .DATA_BITS(DATA_BITS)) rd1_bus();
    // register_bus #(.ADDR_BITS(ADDR_BITS),
    //                .DATA_BITS(DATA_BITS)) wr_bus();
    // logic subtract;
    // logic carry;

    // alu #(.DATA_BITS(DATA_BITS))
    //     arith_unit(.a(rd0_bus.data),
    //                .b(rd1_bus.data),
    //                .cin(subtract),
    //                .result(wr_bus.data),
    //                .cout(carry));

    // register_file #(.ADDR_BITS(ADDR_BITS),
    //                 .DATA_BITS(DATA_BITS))
    //     registers(.clk(clk),
    //             .reset(reset),
    //             .rd0_bus(rd0_bus),
    //             .rd1_bus(rd1_bus),
    //             .wr_bus(wr_bus));

    // assign data_out = rd0_bus.data;


    // register #(.DATA_BITS(8)) ip(  // 8-bit instruction pointer
    //     .clk(clk),
    //     .reset(reset));
    bit [constants_pkg::INSTRUCTION_POINTER_BITS-1:0] ip;
    bit [15:0] ir;

    logic [constants_pkg::MEMORY_ADDRESS_BITS-1:0] mem_address;
    logic [constants_pkg::MEMORY_DATA_BITS-1:0] mem_data;
    logic [constants_pkg::MEMORY_DATA_BITS-1:0] data_read;
    logic mem_read_en, mem_write_en;

    ram #(.ADDR_BITS(constants_pkg::MEMORY_ADDRESS_BITS), 
          .DATA_BITS(constants_pkg::MEMORY_DATA_BITS))
        memory(.address(mem_address),
               .out_en(mem_read_en),
               .write_en(mem_write_en));
    assign memory.data = mem_data;

    bit instruction_ready;
    enum bit [2:0] {IDLE, READ_HIGH_IR, READ_LOW_IR, DECODE} prev_state, state;

    always @(posedge reset) begin
        ip <= 10;
        ir <= 0;
        mem_address <= 0;
        mem_data <= 'bzz;
        mem_read_en <= 0;
        mem_write_en <= 0;
        state <= IDLE;
        prev_state <= IDLE;
        instruction_ready <= 0;
    end;

    always @(posedge clk) begin
        if (state != IDLE)
            ip <= ip + 1;
    end

    always @(posedge clk) begin
        mem_data <= 'bzz;
        case (state)
            READ_HIGH_IR: begin
                if (prev_state == READ_LOW_IR) begin
                    ir[7:0] <= memory.data;
                    instruction_ready <= 1;
                end else begin 
                    instruction_ready <= 0;
                end
                // Prepare read transaction
                mem_address <= ip;
                mem_read_en <= 1;
                prev_state <= READ_HIGH_IR;
                state <= READ_LOW_IR;
            end
            READ_LOW_IR: begin
                instruction_ready <= 0;
                // Now read the data from the completed read transaction
                ir[15:8] <= memory.data;
                // And prepare next transaction
                mem_address <= ip;
                mem_read_en <= 1;
                prev_state <= READ_LOW_IR;
                state <= READ_HIGH_IR;
            end
            DECODE: begin
                state <= IDLE;
            end
            IDLE: begin
                state <= READ_HIGH_IR;
            end
        endcase
    end

    always @(posedge instruction_ready) begin
        $display("Instruction ready: ir=%h%h", ir[15:8], ir[7:0]);
    end

endmodule
`endif