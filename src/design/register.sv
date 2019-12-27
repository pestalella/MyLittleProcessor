`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 11:21:06 AM
// Design Name: 
// Module Name: register
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

`ifndef REGISTER_SV
`define REGISTER_SV

module register(
    input wire clk,
    input wire reset,
    input wire load,
    input wire [7:0] data_in,
    input wire out0_en,
    output logic [7:0] data_out0,
    input wire out1_en,
    output logic [7:0] data_out1
    );
    
    bit [7:0] bits;
    always @(negedge clk)
        if (load) begin
            bits <= data_in;
        end
    
    always @(posedge reset)
        bits <= 0;
    
    assign data_out0 = out0_en? bits : 'bz;    
    assign data_out1 = out1_en? bits : 'bz;    
endmodule

`endif