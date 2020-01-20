`ifndef REGISTER_FILE
`define REGISTER_FILE

`timescale 1ns / 1ps

`include "constants_pkg.sv"
`include "muxers.sv"
`include "register.sv"

import constants_pkg::*;

module register_file #( parameter ADDR_BITS = REGISTER_ADDRESS_BITS,
                                  DATA_BITS = REGISTER_DATA_BITS ) (
    input wire clk,
    input wire reset,
    // register reading
    input bit [ADDR_BITS-1:0] rd0_addr,
    input bit rd0_enable,
    output logic [DATA_BITS-1:0] rd0_data,
    // register reading
    input bit [ADDR_BITS-1:0] rd1_addr,
    input bit rd1_enable,
    output logic [DATA_BITS-1:0] rd1_data,
    // register writing
    input bit [ADDR_BITS-1:0] wr_addr,
    input bit wr_enable,
    input logic [DATA_BITS-1:0] wr_data
    );

    wire [DATA_BITS-1:0] r0_data_out0;
    wire [DATA_BITS-1:0] r1_data_out0;
    wire [DATA_BITS-1:0] r2_data_out0;
    wire [DATA_BITS-1:0] r3_data_out0;
    wire [DATA_BITS-1:0] r4_data_out0;
    wire [DATA_BITS-1:0] r5_data_out0;
    wire [DATA_BITS-1:0] r6_data_out0;
    wire [DATA_BITS-1:0] r7_data_out0;

    wire [DATA_BITS-1:0] r0_data_out1;
    wire [DATA_BITS-1:0] r1_data_out1;
    wire [DATA_BITS-1:0] r2_data_out1;
    wire [DATA_BITS-1:0] r3_data_out1;
    wire [DATA_BITS-1:0] r4_data_out1;
    wire [DATA_BITS-1:0] r5_data_out1;
    wire [DATA_BITS-1:0] r6_data_out1;
    wire [DATA_BITS-1:0] r7_data_out1;

    wire [DATA_BITS-1:0] r0_data_in;
    wire [DATA_BITS-1:0] r1_data_in;
    wire [DATA_BITS-1:0] r2_data_in;
    wire [DATA_BITS-1:0] r3_data_in;
    wire [DATA_BITS-1:0] r4_data_in;
    wire [DATA_BITS-1:0] r5_data_in;
    wire [DATA_BITS-1:0] r6_data_in;
    wire [DATA_BITS-1:0] r7_data_in;

    reg_mux8to1 rd0_mux(.sel(rd0_addr),
                    .in0(r0_data_out0),
                    .in1(r1_data_out0),
                    .in2(r2_data_out0),
                    .in3(r3_data_out0),
                    .in4(r4_data_out0),
                    .in5(r5_data_out0),
                    .in6(r6_data_out0),
                    .in7(r7_data_out0),
                    .out(rd0_data));

    reg_mux8to1 rd1_mux(.sel(rd1_addr),
                    .in0(r0_data_out1),
                    .in1(r1_data_out1),
                    .in2(r2_data_out1),
                    .in3(r3_data_out1),
                    .in4(r4_data_out1),
                    .in5(r5_data_out1),
                    .in6(r6_data_out1),
                    .in7(r7_data_out1),
                    .out(rd1_data));

    reg_demux1to8 wr_demux(.sel(wr_addr),
                    .in(wr_data),
                    .out0(r0_data_in),
                    .out1(r1_data_in),
                    .out2(r2_data_in),
                    .out3(r3_data_in),
                    .out4(r4_data_in),
                    .out5(r5_data_in),
                    .out6(r6_data_in),
                    .out7(r7_data_in));

    register #(.DATA_BITS(DATA_BITS)) r0(
        .clk(clk),
        .reset(reset),
        .data_in(r0_data_in),
        .data_out0(r0_data_out0),
        .data_out1(r0_data_out1),
        .load((wr_addr == 0) && wr_enable),
        .out0_en((rd0_addr == 0) && rd0_enable),
        .out1_en((rd1_addr == 0) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r1(
        .clk(clk),
        .reset(reset),
        .data_in(r1_data_in),
        .data_out0(r1_data_out0),
        .data_out1(r1_data_out1),
        .load((wr_addr == 1) && wr_enable),
        .out0_en((rd0_addr == 1) && rd0_enable),
        .out1_en((rd1_addr == 1) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r2(
        .clk(clk),
        .reset(reset),
        .data_in(r2_data_in),
        .data_out0(r2_data_out0),
        .data_out1(r2_data_out1),
        .load((wr_addr == 2) && wr_enable),
        .out0_en((rd0_addr == 2) && rd0_enable),
        .out1_en((rd1_addr == 2) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r3(
        .clk(clk),
        .reset(reset),
        .data_in(r3_data_in),
        .data_out0(r3_data_out0),
        .data_out1(r3_data_out1),
        .load((wr_addr == 3) && wr_enable),
        .out0_en((rd0_addr == 3) && rd0_enable),
        .out1_en((rd1_addr == 3) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r4(
        .clk(clk),
        .reset(reset),
        .data_in(r4_data_in),
        .data_out0(r4_data_out0),
        .data_out1(r4_data_out1),
        .load((wr_addr == 4) && wr_enable),
        .out0_en((rd0_addr == 4) && rd0_enable),
        .out1_en((rd1_addr == 4) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r5(
        .clk(clk),
        .reset(reset),
        .data_in(r5_data_in),
        .data_out0(r5_data_out0),
        .data_out1(r5_data_out1),
        .load((wr_addr == 5) && wr_enable),
        .out0_en((rd0_addr == 5) && rd0_enable),
        .out1_en((rd1_addr == 5) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r6(
        .clk(clk),
        .reset(reset),
        .data_in(r6_data_in),
        .data_out0(r6_data_out0),
        .data_out1(r6_data_out1),
        .load((wr_addr == 6) && wr_enable),
        .out0_en((rd0_addr == 6) && rd0_enable),
        .out1_en((rd1_addr == 6) && rd1_enable)
        );

    register #(.DATA_BITS(DATA_BITS)) r7(
        .clk(clk),
        .reset(reset),
        .data_in(r7_data_in),
        .data_out0(r7_data_out0),
        .data_out1(r7_data_out1),
        .load((wr_addr == 7) && wr_enable),
        .out0_en((rd0_addr == 7) && rd0_enable),
        .out1_en((rd1_addr == 7) && rd1_enable)
        );

endmodule

`endif