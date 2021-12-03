`include "execution_logger.sv"
`include "execution_unit.sv"
`include "isa_definition.sv"

import isa_pkg::*;

module tb_top ();
    bit clk;
    bit reset;
    int counter;
    integer test_cfg_fd, mem_fd;
    string line;
    string infile_path;
    integer bytes_read;

    bit pwm_out0;
    bit pwm_out1;
    bit pwm_out2;
    bit pwm_out3;

    bit int_req;
    bit int_ack;

    cpu_top dut(
        .clk(clk),
        .reset(reset),
        .pwm_out0(pwm_out0),
        .pwm_out1(pwm_out1),
        .pwm_out2(pwm_out2),
        .pwm_out3(pwm_out3),
        .int_req(int_req),
        .int_ack(int_ack)
    );

    always begin
        #5 clk = ~clk;
        counter += 1;
    end

    initial begin
        clk = 0;
        counter = 0;
        int_req = 0;

        dut.memory.memory['h80] = {NOP, 4'b0};
        dut.memory.memory['h81] = 8'b0;
        dut.memory.memory['h82] = {RETI, 4'b0};
        dut.memory.memory['h83] = 8'b0;

        // Initialize memory with NOPs
        // for (int i = 0; i < 128; i+=2) begin
        //     dut.memory.memory[i+0] = {NOP, 4'b0};
        //     dut.memory.memory[i+1] = 8'b0;
        // end

        // test_cfg_fd = $fopen ("test.cfg", "r");
        // if (test_cfg_fd == 0)
        //     $fatal(2, "Couldn't open 'test.cfg' configuration file. Exiting.");

        // $fgets(infile_path, test_cfg_fd);

        // if (infile_path[infile_path.len()-1] == "\n")
        //     infile_path = infile_path.substr(0, infile_path.len()-2);

        // $display ("Memory file: [%s]", infile_path);

        // mem_fd = $fopen(infile_path, "r");
        // if (mem_fd == 0)
        //     $fatal(2, "%s could not be opened", infile_path);
        // // Read at most 256 bytes
        // bytes_read = $fread(dut.memory.memory, mem_fd);
        // $display("%d bytes read from file %s", bytes_read, infile_path);
        // $fclose(mem_fd);
        // reset the DUT
        reset = 1;
        @(posedge clk) ;
        @(posedge clk) reset = 0;
        // Wait a bit before first interrupt
        repeat (5) begin
            @(posedge clk);
        end
        int_req = 1;
        // Wait a bit and clear the int_req line
        repeat (5) begin
            @(posedge clk);
        end
        int_req = 0;
        // Wait for ISR to finish
        repeat (15) begin
            @(posedge clk);
        end

        // Reset
        reset = 1;
        @(posedge clk);
        @(posedge clk) reset = 0;
        repeat (4) begin
            @(posedge clk);
        end
        int_req = 1;
        // Wait a bit and clear the int_req line
        repeat (5) begin
            @(posedge clk);
        end
        int_req = 0;
        // Wait for ISR to finish
        repeat (15) begin
            @(posedge clk);
        end
    end

endmodule
