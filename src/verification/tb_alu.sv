`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/23/2019 07:44:57 PM
// Design Name: 
// Module Name: tb_alu
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


module tb_alu();
    logic [7:0] a;
    logic [7:0] b;
    logic cin;

    logic [7:0] result;
    logic cout;
    
    alu dut(.a(a), .b(b), .cin(cin), .result(result), .cout(cout));
    
    initial begin
        a = 0;
        b = 0;
        cin = 0;
        result = 0; 
        cout = 0;
        #5 a = 37;
        b = 5;
        #5 cin = 1;
        #5 cin = 0;
        a = 255;
        b = 1;
        #5;
    end
    
    
endmodule
