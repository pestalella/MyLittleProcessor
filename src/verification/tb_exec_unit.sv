`include "execution_unit.sv"
`include "isa_definition.sv"

import isa_pkg::*;

module tb_exec_unit ();
    bit clk;
    bit reset;
    int counter;
    
    exec_unit #(.DATA_BITS(8)) dut(.clk(clk), .reset(reset));

    always begin
        #5 clk = !clk;
        counter += 1;
    end
    
    initial begin
        clk = 0;
        counter = 0;

        // bit [15:0] prog [0:1] = {
        //     {NOP, 12'b0},
        //     {MOVIR, }};

        for (int i = 0; i < 128; i+=2) begin
//            dut.memory.memory[i+0] = {isa_pkg::OpCode'((i/2)%10), 4'b0};
            dut.memory.memory[i+0] = {NOP, 4'b0};
            dut.memory.memory[i+1] = 8'b0;
        end

        dut.memory.memory[0] = {NOP, 4'b0};
        dut.memory.memory[1] = 8'b0;
        dut.memory.memory[2] = {MOVIR, 4'b0000};
        dut.memory.memory[3] = 1;
        dut.memory.memory[4] = {MOVIR, 4'b0001};
        dut.memory.memory[5] = 16;
        dut.memory.memory[6] = {STORE, 4'b0001};
        dut.memory.memory[7] = 16;
        dut.memory.memory[8] = {ADDRR, 4'b0001};
        dut.memory.memory[9] = {4'b0001, 4'b0000};
        dut.memory.memory[10] = {STORE, 4'b0001};
        dut.memory.memory[11] = 7;
        dut.memory.memory[12] = {JZI, 4'b0000};
        dut.memory.memory[13] = 6;

        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;

    end

endmodule