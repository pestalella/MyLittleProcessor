`include "execution_unit.sv"
`include "ram.sv"

module cpu_top (
    input wire clk,
    input wire reset
);
    wire [MEMORY_ADDRESS_BITS-1:0] ram_address;
    wire  [MEMORY_DATA_BITS-1:0] ram_data;
    wire ram_read_en;
    wire ram_write_en;

    exec_unit #(.DATA_BITS(8)) u_exec(
        .clk(clk), 
        .reset(reset),
        .ram_address(ram_address),
        .ram_data(ram_data),
        .ram_read_en(ram_read_en),
        .ram_write_en(ram_write_en));

    ram #(.ADDR_BITS(MEMORY_ADDRESS_BITS), 
          .DATA_BITS(MEMORY_DATA_BITS))
        memory(.clk(clk),
               .address(ram_address),
               .data(ram_data),
               .out_en(ram_read_en),
               .write_en(ram_write_en));  
endmodule
