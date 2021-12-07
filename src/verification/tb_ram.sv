module tb_ram ();
    logic [3:0] address;
    logic [7:0] data;
    logic out_en;
    logic write_en;

    ram #(.ADDR_BITS(4), .DATA_BITS(8))
        dut(.address(address),
            .out_en(out_en),
            .write_en(write_en));

    assign dut.data = data;

    initial begin
        out_en <= 0;

        address <= 0;
        data <= 0;
        #1
        write_en <= 1;
        #1
        write_en <= 0;


        address <= 1;
        data <= 1;

        #1
        write_en <= 1;
        #1
        write_en <= 0;


        address <= 2;
        data <= 2;

        #1
        write_en <= 1;
        #1
        write_en <= 0;
    end
endmodule
