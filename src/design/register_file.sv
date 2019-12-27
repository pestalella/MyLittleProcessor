`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 11:48:47 AM
// Design Name: 
// Module Name: register_file
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`ifndef REGISTER_FILE
`define REGISTER_FILE

`include "register_bus.sv"
`include "register.sv"

module register_file(
    input wire clk,
    input wire reset,
    register_bus rd0_bus,  // register reading
    register_bus rd1_bus,  // register reading
    register_bus wr_bus   // register writing
    );
        
    genvar i;
    for (i = 0; i < 8; i++) begin
        register r(
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