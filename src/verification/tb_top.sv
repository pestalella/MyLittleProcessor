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

    cpu_top dut(.clk(clk),
                .reset(reset),
                .pwm_out0(pwm_out0),
                .pwm_out1(pwm_out1),
                .pwm_out2(pwm_out2),
                .pwm_out3(pwm_out3));

    bind dut execution_logger ec_logger(
        .clk(clk),
        .state(u_exec.state),
        .memory(memory.memory),
        .r0(u_exec.registers.r0.bits),
        .r1(u_exec.registers.r1.bits),
        .r2(u_exec.registers.r2.bits),
        .r3(u_exec.registers.r3.bits),
        .r4(u_exec.registers.r4.bits),
        .r5(u_exec.registers.r5.bits),
        .r6(u_exec.registers.r6.bits),
        .r7(u_exec.registers.r7.bits)
    );

    always begin
        #5 clk = ~clk;
        counter += 1;
    end

    initial begin
        clk = 0;
        counter = 0;

        // Initialize memory with NOPs
        for (int i = 0; i < 128; i+=2) begin
            dut.memory.memory[i+0] = {NOP, 4'b0};
            dut.memory.memory[i+1] = 8'b0;
        end

        test_cfg_fd = $fopen ("test.cfg", "r");
        if (test_cfg_fd == 0)
            $fatal(2, "Couldn't open 'test.cfg' configuration file. Exiting.");

        $fgets(infile_path, test_cfg_fd);

        if (infile_path[infile_path.len()-1] == "\n")
            infile_path = infile_path.substr(0, infile_path.len()-2);

        $display ("Memory file: [%s]", infile_path);

        mem_fd = $fopen(infile_path, "r");
        if (mem_fd == 0)
            $fatal(2, "%s could not be opened", infile_path);
        // Read at most 256 bytes
        bytes_read = $fread(dut.memory.memory, mem_fd);
        $display("%d bytes read from file %s", bytes_read, infile_path);
        $fclose(mem_fd);
        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;

    end

endmodule
