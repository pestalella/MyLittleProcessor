`ifndef FPGA_RAM_SV
`define FPGA_RAM_SV

module fpga_ram(
   output [7:0] DO,     // Output data, width defined by READ_WIDTH parameter
   input [14:0] ADDR,   // Input address, width defined by read/write port depth
   input clk,           // 1-bit input clock
   input [7:0] DI,      // Input data port, width defined by WRITE_WIDTH parameter
   input EN,            // 1-bit input RAM enable
   input REGCE,         // 1-bit input output register enable
   input RST,           // 1-bit input reset
   input [1:0] WE             // Input write enable, width defined by write port depth
);
BRAM_SINGLE_MACRO #(
   .BRAM_SIZE("36Kb"), // Target BRAM, "18Kb" or "36Kb"
   .DEVICE("7SERIES"), // Target Device: "7SERIES"
   .DO_REG(0), // Optional output register (0 or 1)
   .INIT(9'h000000000), // Initial values on output port
   .INIT_FILE ("NONE"),
   .WRITE_WIDTH(8), // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
   .READ_WIDTH(8),  // Valid values are 1-72 (37-72 only valid when BRAM_SIZE="36Kb")
   .SRVAL(9'h0), // Set/Reset value for port output
   .WRITE_MODE("WRITE_FIRST") // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
) BRAM_SINGLE_MACRO_inst (
   .DO(DO),       // Output data, width defined by READ_WIDTH parameter
   .ADDR(ADDR),   // Input address, width defined by read/write port depth
   .CLK(clk),     // 1-bit input clock
   .DI(DI),       // Input data port, width defined by WRITE_WIDTH parameter
   .EN(EN),       // 1-bit input RAM enable
   .REGCE(REGCE), // 1-bit input output register enable
   .RST(RST),     // 1-bit input reset
   .WE(WE)        // Input write enable, width defined by write port depth
);
endmodule

`endif