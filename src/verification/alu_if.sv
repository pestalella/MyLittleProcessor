`ifndef ALU_IF_SV
`define ALU_IF_SV

interface alu_if(input wire dut_zero);
    logic zero;

    assign zero = dut_zero;
endinterface

`endif