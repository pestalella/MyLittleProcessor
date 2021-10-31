`ifndef MEMORY_IO_MUX_SV
`define MEMORY_IO_MUX_SV

`include "constants_pkg.sv"

import constants_pkg::*;

module memory_io_mux(
    input wire clk,

    input wire rd_mem_en,
    input wire [MEMORY_ADDRESS_BITS-1:0] rd_mem_addr,
    output wire   [MEMORY_DATA_BITS-1:0] rd_mem_data,
    input wire wr_mem_en,
    input wire [MEMORY_ADDRESS_BITS-1:0] wr_mem_addr,
    input wire    [MEMORY_DATA_BITS-1:0] wr_mem_data,

    output wire rd_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr,
    input wire    [MEMORY_DATA_BITS-1:0] rd_ram_data,
    output wire wr_ram_en,
    output wire [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr,
    output wire    [MEMORY_DATA_BITS-1:0] wr_ram_data,

    output wire [MEMORY_DATA_BITS-1:0] out_port0,
    output wire out_port0_write_en,
    output wire [MEMORY_DATA_BITS-1:0] out_port1,
    output wire out_port1_write_en,
    output wire [MEMORY_DATA_BITS-1:0] out_port2,
    output wire out_port2_write_en,
    output wire [MEMORY_DATA_BITS-1:0] out_port3,
    output wire out_port3_write_en
    );

    logic [MEMORY_DATA_BITS-1:0] out_port0_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port1_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port2_reg;
    logic [MEMORY_DATA_BITS-1:0] out_port3_reg;

    logic [MEMORY_ADDRESS_BITS-1:0] rd_ram_addr_reg;
    logic [MEMORY_DATA_BITS-1:0] rd_ram_data_reg;
    logic [MEMORY_ADDRESS_BITS-1:0] wr_ram_addr_reg;
    logic [MEMORY_DATA_BITS-1:0] wr_ram_data_reg;

    assign wr_ram_en = wr_mem_en &&
                        ~((wr_mem_addr == 'hfc) |
                          (wr_mem_addr == 'hfd) |
                          (wr_mem_addr == 'hfe) |
                          (wr_mem_addr == 'hff));

    assign rd_ram_en = rd_mem_en &&
                        ~((rd_mem_addr == 'hfc) |
                          (rd_mem_addr == 'hfd) |
                          (rd_mem_addr == 'hfe) |
                          (rd_mem_addr == 'hff));

    assign wr_ram_addr_reg = wr_mem_addr;
    assign wr_ram_data_reg = wr_mem_data;
    assign rd_ram_addr_reg = rd_mem_addr;
    assign rd_ram_data_reg = rd_ram_data;

    assign wr_ram_addr = wr_ram_addr_reg;
    assign wr_ram_data = wr_ram_data_reg;
    assign rd_ram_addr = rd_ram_addr_reg;
    assign rd_mem_data = rd_ram_data_reg;

    assign out_port0_write_en = wr_mem_en && (wr_mem_addr == 'hfc);
    assign out_port1_write_en = wr_mem_en && (wr_mem_addr == 'hfd);
    assign out_port2_write_en = wr_mem_en && (wr_mem_addr == 'hfe);
    assign out_port3_write_en = wr_mem_en && (wr_mem_addr == 'hff);

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
