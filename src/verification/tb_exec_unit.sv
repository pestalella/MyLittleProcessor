`include "execution_logger.sv"
`include "execution_unit.sv"
`include "isa_definition.sv"

import isa_pkg::*;

module tb_exec_unit ();
    bit clk;
    bit reset;
    int counter;
    integer mem_fd;
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
        .memory(memory.memory),
        .r0(u_exec.registers.r0.bits),
        .r1(u_exec.registers.r1.bits),
        .r2(u_exec.registers.r2.bits)
    );

    always begin
        #5 clk = !clk;
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

        if ($value$plusargs("memory_file=%s", infile_path)) begin
            $display ("memory_file=%s", infile_path);
        end else
            $fatal(2, "Please specify an input file with the memory contents '+memory_file=<mem_file>'");

        mem_fd = $fopen(infile_path, "r");
        if (mem_fd == 0)
            $fatal(2, "%s could not be opened", infile_path);
        // Read at most 256 bytes
        bytes_read = $fread(dut.memory.memory, mem_fd);
        $display("%d bytes read from file %s", bytes_read, infile_path);
        $fclose(mem_fd);
/*        dut.memory.memory[0] = {NOP, 4'b0};
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
*/
        // reset the DUT
        reset = 1;
        @(posedge clk) reset = 0;

    end

endmodule