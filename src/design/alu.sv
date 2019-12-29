`ifndef ALU_SV
`define ALU_SV

`timescale 1ns / 1ps

module alu  #(parameter DATA_BITS  = 8) (
    input wire clk,
    input wire [DATA_BITS-1:0] a,
    input wire [DATA_BITS-1:0] b,
    input wire cin,
    output logic [DATA_BITS-1:0] result,
    output logic cout
    );

    // If cin==1, it means the request is to subtract instead of add
    always @(posedge clk)
        {cout, result} <= cin? (a + ~b + cin) : (a + b);
endmodule

`endif