`ifndef ALU_SV
`define ALU_SV

`timescale 1ns / 1ps

module alu  #(parameter DATA_BITS  = 8) (
    input wire clk,
    input wire reset,
    input wire [DATA_BITS-1:0] a,
    input wire [DATA_BITS-1:0] b,
    input wire cin,
    output logic [DATA_BITS-1:0] result,
    output logic cout,
    output logic zero
    );

    logic [DATA_BITS:0] reg_result;

    // If cin==1, it means the request is to subtract instead of add
    assign reg_result = cin? (a + ~b + cin) : (a + b);

    always_ff @(posedge clk) begin
        {cout, result} <= reg_result;
                  zero <= reset? 0 : ~(|reg_result);
    end
endmodule

`endif