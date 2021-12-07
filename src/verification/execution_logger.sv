`ifndef EXECUTION_LOGGER_SV
`define EXECUTION_LOGGER_SV

`timescale 1ns / 1ps

module execution_logger (
    input wire clk,
    input constants_pkg::ExecutionStage state,
    input logic [7:0] memory [0:255],
    input wire [7:0] r0,
    input wire [7:0] r1,
    input wire [7:0] r2,
    input wire [7:0] r3,
    input wire [7:0] r4,
    input wire [7:0] r5,
    input wire [7:0] r6,
    input wire [7:0] r7
);
    import constants_pkg::*;

    always @(posedge clk) begin
        if (state == FETCH_END) begin
            $display("Memory: %h %h %h %h %h %h %h %h r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                memory[0:3], memory[4:7],
                memory[8:11], memory[12:15],
                memory[16:19], memory[20:23],
                memory[24:27], memory[28:31],
                r0, r1, r2, r3, r4, r5, r6, r7);
        end
    end
endmodule

`endif
