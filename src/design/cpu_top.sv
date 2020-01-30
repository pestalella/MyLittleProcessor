`include "execution_unit.sv"
`include "memory_io_mux.sv"
`include "pwm_driver.sv"
`include "ram.sv"
`include "rom.sv"

module cpu_top (
    input wire clk,
    input wire reset,
    output wire pwm_out0,
    output wire pwm_out1,
    output wire pwm_out2,
    output wire pwm_out3
);
    wire [MEMORY_ADDRESS_BITS-1:0] exec_unit_rd_mem_addr;
    wire [MEMORY_DATA_BITS-1:0] exec_unit_rd_mem_data;
    wire [MEMORY_ADDRESS_BITS-1:0] exec_unit_wr_mem_addr;
    wire [MEMORY_DATA_BITS-1:0] exec_unit_wr_mem_data;
    wire exec_unit_rd_mem_en;
    wire exec_unit_wr_mem_en;

    wire rd_ram_en;
    wire [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr;
    wire    [MEMORY_DATA_BITS-1:0] rd_ram_data;
    wire wr_ram_en;
    wire [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr;
    wire    [MEMORY_DATA_BITS-1:0] wr_ram_data;

    wire pwm_out0_set_cutoff_en;
    wire pwm_out1_set_cutoff_en;
    wire pwm_out2_set_cutoff_en;
    wire pwm_out3_set_cutoff_en;
    wire [MEMORY_DATA_BITS-1:0] pwm_out0_cutoff_value;
    wire [MEMORY_DATA_BITS-1:0] pwm_out1_cutoff_value;
    wire [MEMORY_DATA_BITS-1:0] pwm_out2_cutoff_value;
    wire [MEMORY_DATA_BITS-1:0] pwm_out3_cutoff_value;

    exec_unit #(.DATA_BITS(8)) u_exec(
        .clk(clk),
        .reset(reset),

        .rd_ram_en(exec_unit_rd_mem_en),
        .rd_ram_addr(exec_unit_rd_mem_addr),
        .rd_ram_data(exec_unit_rd_mem_data),

        .wr_ram_en(exec_unit_wr_mem_en),
        .wr_ram_addr(exec_unit_wr_mem_addr),
        .wr_ram_data(exec_unit_wr_mem_data));

    memory_io_mux io_mapper(
        .clk(clk),

        .rd_mem_en(exec_unit_rd_mem_en),
        .rd_mem_addr(exec_unit_rd_mem_addr),
        .rd_mem_data(exec_unit_rd_mem_data),

        .wr_mem_en(exec_unit_wr_mem_en),
        .wr_mem_addr(exec_unit_wr_mem_addr),
        .wr_mem_data(exec_unit_wr_mem_data),


        .rd_ram_en(rd_ram_en),
        .rd_ram_addr(rd_ram_addr),
        .rd_ram_data(rd_ram_data),

        .wr_ram_en(wr_ram_en),
        .wr_ram_addr(wr_ram_addr),
        .wr_ram_data(wr_ram_data),

        .out_port0(pwm_out0_cutoff_value),
        .out_port0_write_en(pwm_out0_set_cutoff_en),
        .out_port1(pwm_out1_cutoff_value),
        .out_port1_write_en(pwm_out1_set_cutoff_en),
        .out_port2(pwm_out2_cutoff_value),
        .out_port2_write_en(pwm_out2_set_cutoff_en),
        .out_port3(pwm_out3_cutoff_value),
        .out_port3_write_en(pwm_out3_set_cutoff_en)
    );

    rom #(.ADDR_BITS(MEMORY_ADDRESS_BITS),
          .DATA_BITS(MEMORY_DATA_BITS),
          .memory_file("pwm.mem"))
        memory(.rd_en(rd_ram_en),
               .rd_addr(rd_ram_addr),
               .rd_data(rd_ram_data));
    // ram #(.ADDR_BITS(MEMORY_ADDRESS_BITS),
    //       .DATA_BITS(MEMORY_DATA_BITS))
    //     memory(.clk(clk),
    //            .rd_en(rd_ram_en),
    //            .rd_addr(rd_ram_addr),
    //            .rd_data(rd_ram_data),
    //            .wr_en(wr_ram_en),
    //            .wr_addr(wr_ram_addr),
    //            .wr_data(wr_ram_data));

    pwm_driver pwm_driver0(
        .clk(clk),
        .reset(reset),
        .set_cutoff_en(pwm_out0_set_cutoff_en),
        .cutoff_value(pwm_out0_cutoff_value),
        .pwm_out(pwm_out0));

    pwm_driver pwm_driver1(
        .clk(clk),
        .reset(reset),
        .set_cutoff_en(pwm_out1_set_cutoff_en),
        .cutoff_value(pwm_out1_cutoff_value),
        .pwm_out(pwm_out1));

    pwm_driver pwm_driver2(
        .clk(clk),
        .reset(reset),
        .set_cutoff_en(pwm_out2_set_cutoff_en),
        .cutoff_value(pwm_out2_cutoff_value),
        .pwm_out(pwm_out2));

    pwm_driver pwm_driver3(
        .clk(clk),
        .reset(reset),
        .set_cutoff_en(pwm_out3_set_cutoff_en),
        .cutoff_value(pwm_out3_cutoff_value),
        .pwm_out(pwm_out3));
endmodule
