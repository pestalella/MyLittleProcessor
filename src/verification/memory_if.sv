`ifndef MEMORY_IF_SV
`define MEMORY_IF_SV

interface memory_if();
    import constants_pkg::*;

    wire rd_en;
    wire [MEMORY_ADDRESS_BITS-1:0] rd_addr;
    logic [MEMORY_DATA_BITS-1:0] rd_data;

    wire wr_en;
    wire [MEMORY_ADDRESS_BITS-1:0] wr_addr;
    wire [MEMORY_DATA_BITS-1:0] wr_data;

    modport mem_dut(input rd_data, output rd_en, rd_addr, wr_en, wr_addr, wr_data);
    modport mem_mon(input rd_en, rd_addr, wr_en, wr_addr, wr_data, output rd_data);
endinterface

`endif
