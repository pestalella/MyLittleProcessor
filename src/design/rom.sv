`ifndef MLP_ROM_SV
`define MLP_ROM_SV

module rom #( parameter ADDR_BITS = 8,
                        DATA_BITS = 8,
                        memory_file = "" )
    (input  wire rd_en,
     input  wire [ADDR_BITS-1:0] rd_addr,
     output wire [DATA_BITS-1:0] rd_data);

    bit [DATA_BITS-1:0] memory [0: (1<<ADDR_BITS) - 1];

    initial $readmemh(memory_file, memory);

    assign rd_data = rd_en ? memory[rd_addr] : {DATA_BITS{1'bz}};

endmodule

`endif