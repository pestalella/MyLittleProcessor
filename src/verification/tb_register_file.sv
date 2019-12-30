`timescale 1ns / 1ps

`include "register_file.sv"

module tb_register_file();
    logic clk;
    logic reset;
    
    logic [7:0] saved_value0;
    logic [7:0] saved_value1;
    
    always begin
        #5 clk = !clk;
    end
    
    logic [2:0] rd0_addr;
    logic [2:0] rd1_addr;
    logic [2:0] wr_addr;
    logic rd0_enable;
    logic rd1_enable;
    logic wr_enable;
    logic [7:0] rd0_data;
    logic [7:0] rd1_data;
    logic [7:0] wr_data;

    register_file dut(.clk(clk), 
                      .reset(reset),
                      .rd0_enable(rd0_enable),
                      .rd0_addr(rd0_addr),
                      .rd0_data(rd0_data),
                      .rd1_enable(rd1_enable),
                      .rd1_addr(rd1_addr),
                      .rd1_data(rd1_data),
                      .wr_enable(wr_enable),
                      .wr_addr(wr_addr),
                      .wr_data(wr_data));
    
    initial begin
        clk = 0;
        reset = 0;
        rd0_enable = 0;
        rd1_enable = 0;
        #7;
        for (int i = 0; i < 8; i++) begin
            wr_addr = i;
            wr_data = 'd42 + i;
            wr_enable = 1;
            #5;
            wr_enable = 0;
            #5;
        end
        for (int i = 0; i < 8; i++) begin
            rd0_addr = i;
            rd0_enable = 1;

            rd1_addr = i;
            rd1_enable = 1;
            @(posedge clk) begin
                if (rd0_data != 'd42 + i)
                    $display("r%d: expected=%d actual=%d", i, 'd41+i, rd0_data);
                if (rd1_data != 'd42 + i)
                    $display("r%d: expected=%d actual=%d", i, 'd41+i, rd1_data);
            end
            #5;
            rd0_addr = 0;
            rd1_addr = 0;
            rd0_enable = 0;
            rd1_enable = 0;
            #5;
        end    
        
        @(posedge clk) begin
            rd0_addr = 7;
            rd0_enable = 1;
            wr_addr = 7;
            wr_data = 99;
            wr_enable = 1;
        end
        #1
        saved_value0 = rd0_data;
        #10;
        saved_value1 = rd0_data;
        #10;
    end
endmodule
