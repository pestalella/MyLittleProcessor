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

    wire [DATA_BITS-1:0] r_data_out0 [7:0];
    wire [DATA_BITS-1:0] r_data_out1 [7:0];
    wire [DATA_BITS-1:0] r_data_in [7:0];

    mux8to1 rd0_mux(.sel(rd0_addr),
                    .in0(r_data_out0[0]),
                    .in1(r_data_out0[1]),
                    .in2(r_data_out0[2]),
                    .in3(r_data_out0[3]),
                    .in4(r_data_out0[4]),
                    .in5(r_data_out0[5]),
                    .in6(r_data_out0[6]),
                    .in7(r_data_out0[7]),
                    .out(rd0_data));

    mux8to1 rd1_mux(.sel(rd0_addr),
                    .in0(r_data_out1[0]),
                    .in1(r_data_out1[1]),
                    .in2(r_data_out1[2]),
                    .in3(r_data_out1[3]),
                    .in4(r_data_out1[4]),
                    .in5(r_data_out1[5]),
                    .in6(r_data_out1[6]),
                    .in7(r_data_out1[7]),
                    .out(rd0_data));

    demux1to8 wr_demux(.sel(wr_addr),
                    .in(wr_data),
                    .out0(r_data_in[0]),
                    .out1(r_data_in[1]),
                    .out2(r_data_in[2]),
                    .out3(r_data_in[3]),
                    .out4(r_data_in[4]),
                    .out5(r_data_in[5]),
                    .out6(r_data_in[6]),
                    .out7(r_data_in[7]));

    genvar i;
    for (i = 0; i < 8; i++) begin : regs
        register #(.DATA_BITS(DATA_BITS)) r(
            .clk(clk),
            .reset(reset),
            .data_in(r_data_in[i]),
            .data_out0(r_data_out0[i]),
            .data_out1(r_data_out1[i]),
            .load((wr_addr == i) && wr_enable),
            .out0_en((rd0_addr == i) && rd0_enable),
            .out1_en((rd1_addr == i) && rd1_enable)
            );
    end

endmodule

`endif