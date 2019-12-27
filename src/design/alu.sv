`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 07:03:45 PM
// Design Name: 
// Module Name: alu
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


module alu(
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output logic [7:0] result,
    output logic cout
    );
    // If cin==1, it means the request is to subtract instead of add
    assign {cout, result} = cin? (a + ~b + cin) : (a + b);
endmodule
