`ifndef REGISTER_FILE
`define REGISTER_FILE

`timescale 1ns / 1ps

`include "constants_pkg.sv"
`include "muxers.sv"
`include "register.sv"

module register_file #( parameter DATA_BITS = REGISTER_DATA_BITS ) (
    import constants_pkg::*;

    input wire clk,
    input wire reset_n,
    // register reading
    input bit [3:0] rd0_addr,
    input bit rd0_enable,
    output logic [DATA_BITS-1:0] rd0_data,
    // register reading
    input bit [3:0] rd1_addr,
    input bit rd1_enable,
    output logic [DATA_BITS-1:0] rd1_data,
    // register writing
    input bit [3:0] wr_addr,
    input bit wr_enable,
    input logic [DATA_BITS-1:0] wr_data
    );

    wire [15:0][DATA_BITS-1:0] r_data_out0;
    wire [15:0][DATA_BITS-1:0] r_data_out1;
    wire [15:0][DATA_BITS-1:0] r_data_in;

    mux16to1 rd0_mux(.sel(rd0_addr),
                    .in0(r_data_out0[0]),
                    .in1(r_data_out0[1]),
                    .in2(r_data_out0[2]),
                    .in3(r_data_out0[3]),
                    .in4(r_data_out0[4]),
                    .in5(r_data_out0[5]),
                    .in6(r_data_out0[6]),
                    .in7(r_data_out0[7]),
                    .in8(r_data_out0[8]),
                    .in9(r_data_out0[9]),
                    .in10(r_data_out0[10]),
                    .in11(r_data_out0[11]),
                    .in12(r_data_out0[12]),
                    .in13(r_data_out0[13]),
                    .in14(r_data_out0[14]),
                    .in15(r_data_out0[15]),
                    .out(rd0_data));

    mux16to1 rd1_mux(.sel(rd1_addr),
                    .in0(r_data_out1[0]),
                    .in1(r_data_out1[1]),
                    .in2(r_data_out1[2]),
                    .in3(r_data_out1[3]),
                    .in4(r_data_out1[4]),
                    .in5(r_data_out1[5]),
                    .in6(r_data_out1[6]),
                    .in7(r_data_out1[7]),
                    .in8(r_data_out1[8]),
                    .in9(r_data_out1[9]),
                    .in10(r_data_out1[10]),
                    .in11(r_data_out1[11]),
                    .in12(r_data_out1[12]),
                    .in13(r_data_out1[13]),
                    .in14(r_data_out1[14]),
                    .in15(r_data_out1[15]),
                    .out(rd1_data));

    demux1to16 wr_demux(.sel(wr_addr),
                    .in(wr_data),
                    .out0(r_data_in[0]),
                    .out1(r_data_in[1]),
                    .out2(r_data_in[2]),
                    .out3(r_data_in[3]),
                    .out4(r_data_in[4]),
                    .out5(r_data_in[5]),
                    .out6(r_data_in[6]),
                    .out7(r_data_in[7]),
                    .out8(r_data_in[8]),
                    .out9(r_data_in[9]),
                    .out10(r_data_in[10]),
                    .out11(r_data_in[11]),
                    .out12(r_data_in[12]),
                    .out13(r_data_in[13]),
                    .out14(r_data_in[14]),
                    .out15(r_data_in[15])
                    );

    genvar i;
    for (i = 0; i < 16; i++) begin : regs
        register #(.DATA_BITS(DATA_BITS)) r(
            .clk(clk),
            .reset_n(reset_n),
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
