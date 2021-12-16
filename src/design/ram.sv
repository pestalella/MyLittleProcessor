`ifndef MLP_RAM_SV
`define MLP_RAM_SV

module ram #(
    parameter ADDR_BITS = 8,
              DATA_BITS = 8,
              memory_file = "" )
    (input clk,
     input  wire rd_en,
     input  wire [ADDR_BITS-1:0] rd_addr,
     output wire [DATA_BITS-1:0] rd_data,
     input  wire wr_en,
     input  wire [ADDR_BITS-1:0] wr_addr,
     input  wire [DATA_BITS-1:0] wr_data);

    logic [DATA_BITS-1:0] memory [0: (1<<ADDR_BITS) - 1];

    initial $readmemh(memory_file, memory);

    assign rd_data = rd_en ? memory[rd_addr] : {DATA_BITS{1'bz}};

    always @(posedge clk)
        if (wr_en)
            memory[wr_addr] <= wr_data;
endmodule
`endif
