`ifndef REGFILE_IF_SV
`define REGFILE_IF_SV

interface regfile_if ();
    logic clk;
    logic reset_n;
    // register reading
    logic [REGISTER_ADDRESS_BITS-1:0] rd0_addr;
    logic rd0_enable;
    logic [REGISTER_DATA_BITS-1:0] rd0_data;
    // register reading
    logic [REGISTER_ADDRESS_BITS-1:0] rd1_addr;
    logic rd1_enable;
    logic [REGISTER_DATA_BITS-1:0] rd1_data;
    // register writing
    logic [REGISTER_ADDRESS_BITS-1:0] wr_addr;
    logic wr_enable;
    logic [REGISTER_DATA_BITS-1:0] wr_data;

    modport rf_dut(input clk, reset_n,
                   output wr_addr, wr_enable, wr_data);
    modport rf_mon(input clk, reset_n, wr_addr, wr_enable, wr_data);

endinterface

`endif
