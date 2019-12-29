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

    task read_mem(input bit[constants_pkg::MEMORY_ADDRESS_BITS-1:0] address);
        mem_data <= 'bzz;
        mem_address <= address;
        mem_read_en <= 1;
        @(negedge clk) data_read <= memory.data;
        mem_read_en <= 0;
    endtask

    always @(posedge reset) begin
        ip <= 0;
        ir <= 0;
        mem_address <= 0;
        mem_data <= 'bzz;
        mem_read_en <= 0;
        mem_write_en <= 0;
    end;


    always @(posedge clk) begin
        read_mem(ip);
        ir[15:8] <= data_read;
        ip++;
        read_mem(ip);
        ir[7:0] <= data_read;
        ip++;
    end

endmodule
`endif