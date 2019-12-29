`ifndef REGISTER_FILE
`define REGISTER_FILE

`timescale 1ns / 1ps

`include "register_bus.sv"
`include "register.sv"

module register_file #( parameter ADDR_BITS = 3, DATA_BITS = 8 ) (
    input wire clk,
    input wire reset,
    register_bus rd0_bus,  // register reading
    register_bus rd1_bus,  // register reading
    register_bus wr_bus    // register writing
    );
        
    genvar i;
    for (i = 0; i < (1 << ADDR_BITS); i++) begin
        register #(.DATA_BITS(DATA_BITS)) r(
            .clk(clk),
            .reset(reset),
            .data_in(wr_bus.data),
            .data_out0(rd0_bus.data),
            .data_out1(rd1_bus.data),
            .load((wr_bus.addr == i) && wr_bus.enable),
            .out0_en((rd0_bus.addr == i) && rd0_bus.enable),
            .out1_en((rd1_bus.addr == i) && rd1_bus.enable)
            );
    end

endmodule

`endif