`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 11:52:42 AM
// Design Name: 
// Module Name: register_if
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

`ifndef REGISTER_BUS_SV
`define REGISTER_BUS_SV

interface register_bus;
    bit [2:0] addr;
    bit enable;
    logic [7:0] data;
endinterface

`endif