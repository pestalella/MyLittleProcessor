`timescale 1ns / 1ps

`ifndef REGISTER_BUS_SV
`define REGISTER_BUS_SV

interface register_bus #( parameter ADDR_BITS = 3, DATA_BITS = 8 );
    bit [ADDR_BITS-1:0] addr;
    bit enable;
    logic [DATA_BITS-1:0] data;
endinterface

`endif