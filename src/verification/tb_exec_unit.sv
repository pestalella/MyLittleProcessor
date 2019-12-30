`include "execution_unit.sv"

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

        for (int i = 0; i < 128; i++) begin
            dut.memory.memory[i] = i;
        end
        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;

    end

endmodule