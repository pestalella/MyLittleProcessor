`timescale 1ns / 1ps

`include "register_bus.sv"
`include "register_file.sv"

module tb_register_file();
    logic clk;
    logic reset;
    
    logic [7:0] saved_value0;
    logic [7:0] saved_value1;
    
    always begin
        #5 clk = !clk;
    end
    
    register_bus wr_bus();
    register_bus rd0_bus();
    register_bus rd1_bus();
    
    register_file dut(.clk(clk), 
                      .reset(reset),
                      .rd0_bus(rd0_bus), 
                      .rd1_bus(rd1_bus), 
                      .wr_bus(wr_bus));
    
    initial begin
        clk = 0;
        reset = 0;
        rd0_bus.enable = 0;
        rd1_bus.enable = 0;
        #7;
        for (int i = 0; i < 8; i++) begin
            wr_bus.addr = i;
            wr_bus.data = 'd42 + i;
            wr_bus.enable = 1;
            #5;
            wr_bus.enable = 0;
            #5;
        end
        for (int i = 0; i < 8; i++) begin
            rd0_bus.addr = i;
            rd0_bus.enable = 1;

            rd1_bus.addr = i;
            rd1_bus.enable = 1;
            @(posedge clk) begin
                if (rd0_bus.data != 'd42 + i)
                    $display("r%d: expected=%d actual=%d", i, 'd41+i, rd0_bus.data);
                if (rd1_bus.data != 'd42 + i)
                    $display("r%d: expected=%d actual=%d", i, 'd41+i, rd1_bus.data);
            end
            #5;
            rd0_bus.addr = 0;
            rd1_bus.addr = 0;
            rd0_bus.enable = 0;
            rd1_bus.enable = 0;
            #5;
        end    
        
        @(posedge clk) begin
            rd0_bus.addr = 7;
            rd0_bus.enable = 1;
            wr_bus.addr = 7;
            wr_bus.data = 99;
            wr_bus.enable = 1;
        end
        #1
        saved_value0 = rd0_bus.data;
        #10;
        saved_value1 = rd0_bus.data;
        #10;
    end
endmodule
