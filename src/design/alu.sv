`ifndef ALU_SV
`define ALU_SV

`timescale 1ns / 1ps

module alu  #(parameter DATA_BITS  = 8) (
    input wire reset,
    input wire [DATA_BITS-1:0] a,
    input wire [DATA_BITS-1:0] b,
    input wire cin,
    output logic [DATA_BITS-1:0] result,
    output wire cout,
    output wire zero
    );

    bit zero_reg;

    assign zero = zero_reg;
    // If cin==1, it means the request is to subtract instead of add
    assign {cout, result} = cin? (a + ~b + cin) : (a + b);

    always_comb
        zero_reg <= reset? 0 : ~(|{cout, result});
endmodule

`endif