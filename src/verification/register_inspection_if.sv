`ifndef REGISTER_INSPECTION_IF
`define REGISTER_INSPECTION_IF

interface register_inspection_if();
    import constants_pkg::*;

    logic clk;
    logic [REGISTER_DATA_BITS-1:0] r0;
    logic [REGISTER_DATA_BITS-1:0] r1;
    logic [REGISTER_DATA_BITS-1:0] r2;
    logic [REGISTER_DATA_BITS-1:0] r3;
    logic [REGISTER_DATA_BITS-1:0] r4;
    logic [REGISTER_DATA_BITS-1:0] r5;
    logic [REGISTER_DATA_BITS-1:0] r6;
    logic [REGISTER_DATA_BITS-1:0] r7;
endinterface

`endif
