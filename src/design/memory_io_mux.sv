`ifndef MEMORY_IO_MUX_SV
`define MEMORY_IO_MUX_SV

`include "constants_pkg.sv"

module memory_io_mux(
    input wire clk,

    input wire rd_mem_en,
    input wire [constants_pkg::MEMORY_ADDRESS_BITS-1:0] rd_mem_addr,
    output wire   [constants_pkg::MEMORY_DATA_BITS-1:0] rd_mem_data,
    input wire wr_mem_en,
    input wire [constants_pkg::MEMORY_ADDRESS_BITS-1:0] wr_mem_addr,
    input wire    [constants_pkg::MEMORY_DATA_BITS-1:0] wr_mem_data,

    output wire rd_ram_en,
    output wire [constants_pkg::MEMORY_ADDRESS_BITS-1:0] rd_ram_addr,
    input wire    [constants_pkg::MEMORY_DATA_BITS-1:0] rd_ram_data,
    output wire wr_ram_en,
    output wire [constants_pkg::MEMORY_ADDRESS_BITS-1:0] wr_ram_addr,
    output wire    [constants_pkg::MEMORY_DATA_BITS-1:0] wr_ram_data,

    output wire [constants_pkg::MEMORY_DATA_BITS-1:0] out_port0,
    output wire out_port0_write_en,
    output wire [constants_pkg::MEMORY_DATA_BITS-1:0] out_port1,
    output wire out_port1_write_en,
    output wire [constants_pkg::MEMORY_DATA_BITS-1:0] out_port2,
    output wire out_port2_write_en,
    output wire [constants_pkg::MEMORY_DATA_BITS-1:0] out_port3,
    output wire out_port3_write_en
    );

    import constants_pkg::*;

    logic [MEMORY_DATA_BITS-1:0] out_port0_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port1_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port2_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port3_reg;

    logic [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr_reg;
    logic [MEMORY_DATA_BITS-1:0] rd_ram_data_reg;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr_reg;
    logic [MEMORY_DATA_BITS-1:0] wr_ram_data_reg;

    assign wr_ram_en = wr_mem_en &&
                        ~((wr_mem_addr == 'hfffc) |
                          (wr_mem_addr == 'hfffd) |
                          (wr_mem_addr == 'hfffe) |
                          (wr_mem_addr == 'hffff));

    assign rd_ram_en = rd_mem_en &&
                        ~((rd_mem_addr == 'hfffc) |
                          (rd_mem_addr == 'hfffd) |
                          (rd_mem_addr == 'hfffe) |
                          (rd_mem_addr == 'hffff));

    assign wr_ram_addr_reg = wr_mem_addr;
    assign wr_ram_data_reg = wr_mem_data;
    assign rd_ram_addr_reg = rd_mem_addr;
    assign rd_ram_data_reg = rd_ram_data;

    assign wr_ram_addr = wr_ram_addr_reg;
    assign wr_ram_data = wr_ram_data_reg;
    assign rd_ram_addr = rd_ram_addr_reg;
    assign rd_mem_data = rd_ram_data_reg;

    assign out_port0_write_en = wr_mem_en && (wr_mem_addr == 'hfffc);
    assign out_port1_write_en = wr_mem_en && (wr_mem_addr == 'hfffd);
    assign out_port2_write_en = wr_mem_en && (wr_mem_addr == 'hfffe);
    assign out_port3_write_en = wr_mem_en && (wr_mem_addr == 'hffff);

    assign out_port0_reg = wr_mem_data;
    assign out_port1_reg = wr_mem_data;
    assign out_port2_reg = wr_mem_data;
    assign out_port3_reg = wr_mem_data;

    assign out_port0 = out_port0_reg;
    assign out_port1 = out_port1_reg;
    assign out_port2 = out_port2_reg;
    assign out_port3 = out_port3_reg;
endmodule

`endif
