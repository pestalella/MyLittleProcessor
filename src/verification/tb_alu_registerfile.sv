`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/24/2019 12:11:33 PM
// Design Name: 
// Module Name: tb_alu_registerfile
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


module tb_alu_registerfile( );
    logic clk;
    logic reset;
    
    always begin
        #5 clk = !clk;
    end
    
    register_bus busA();
    register_bus busB();
    register_bus busR();
    logic subtract;
    logic carry;
    
    alu dutALU(busA.data, busB.data, subtract, busR.data, carry);

    register_file dutRegs(.clk(clk),
                          .reset(reset),
                          .rd0_bus(busA), 
                          .rd1_bus(busB), 
                          .wr_bus(busR));
    
    initial begin
        clk = 0;
        reset = 0;
        subtract = 0;
        busA.enable = 0;
        busB.enable = 0;
        busR.enable = 0;
        // Load registers ri = i
        for (int i = 0; i < 8; i++) begin
            busR.addr = i;
            busR.data = i;
            busR.enable = 1;
            #7;
            busR.enable = 0;
            #3;
        end
        busA.addr = 2;
        busB.addr = 3;
        busR.addr = 4;   // r4 := r2 + r3;
        #1 busA.enable = 1;
        busB.enable = 1;
        #1 busR.enable = 1;
        @(posedge clk) begin
            #1 busR.enable = 0;
            busA.enable = 0;
            busB.enable = 0;
        end
        
        busA.addr = 2;
        busB.addr = 7;
        busR.addr = 2;   // r2 := r2 + r7;
        busA.enable = 1;
        busB.enable = 1;
        @(posedge clk) begin
            busR.enable = 1;
        end
        @(negedge clk) begin
            busR.enable = 0;
        end
        
        #10;
    end
endmodule
