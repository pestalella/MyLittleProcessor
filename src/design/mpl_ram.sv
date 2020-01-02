`ifndef MLP_RAM_SV
`define MLP_RAM_SV

module ram #( parameter ADDR_BITS = 8, DATA_BITS = 8 )
    (input wire [ADDR_BITS-1:0] address,
     inout logic [DATA_BITS-1:0] data,
     input wire out_en,
     input wire write_en);

    bit [DATA_BITS-1:0] memory [0: (1<<ADDR_BITS) - 1];

    assign data = out_en ? memory[address] : {DATA_BITS{1'bz}};
    always @(posedge write_en)
            memory[address] = data;

//    always @(write_en or out_en)
//        if (write_en && out_en)
//            $error("RAM: out_en and write_en both active");

endmodule
`endif