`ifndef REGISTER_SV
`define REGISTER_SV

`timescale 1ns / 1ps

module register #(parameter DATA_BITS  = 8) (
    input wire clk,
    input wire reset,
    input wire load,
    input wire [DATA_BITS-1:0] data_in,
    input wire out0_en,
    output wire [DATA_BITS-1:0] data_out0,
    input wire out1_en,
    output wire [DATA_BITS-1:0] data_out1
    );
    
    bit [DATA_BITS-1:0] bits;
    always @(negedge clk or posedge reset)
        if (reset)
            bits <= 0;
        else if (load)
            bits <= data_in;
        
    assign data_out0 = out0_en? bits : {DATA_BITS{1'bz}};    
    assign data_out1 = out1_en? bits : {DATA_BITS{1'bz}};    
endmodule

`endif