`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2019 07:03:18 PM
// Design Name: 
// Module Name: constants_pkg
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
`ifndef CONSTANTS_PKG_SV
`define CONSTANTS_PKG_SV

package constants_pkg;
    typedef enum bit [1:0] {REG_READ, REG_WRITE, ADD, SUB} ALUOp;
endpackage

`endif