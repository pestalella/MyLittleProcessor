`timescale 1ns / 1ps

module tb_alu_registerfile( );
    logic clk;
    logic reset_n;

    always begin
        #5 clk = !clk;
    end

    logic subtract;
    logic carry;

    logic [2:0] rd0_addr;
    logic [2:0] rd1_addr;
    logic [2:0] wr_addr;
    logic rd0_enable;
    logic rd1_enable;
    logic wr_enable;
    logic [7:0] rd0_data;
    logic [7:0] rd1_data;
    logic [7:0] wr_data;

    alu dutALU(.a(rd0_data),
               .b(rd1_data),
               .cin(subtract),
               .result(wr_data),
               .cout(carry));

    register_file dutRegs(.clk(clk),
                      .reset_n(reset_n),
                      .rd0_enable(rd0_enable),
                      .rd0_addr(rd0_addr),
                      .rd0_data(rd0_data),
                      .rd1_enable(rd1_enable),
                      .rd1_addr(rd1_addr),
                      .rd1_data(rd1_data),
                      .wr_enable(wr_enable),
                      .wr_addr(wr_addr),
                      .wr_data(wr_data));

    initial begin
        clk <= 0;
        reset_n <= 1;
        subtract <= 0;
        rd0_enable <= 0;
        rd1_enable <= 0;
        wr_enable <= 0;
        // Load registers ri = i
        for (int i = 0; i < 8; i++) begin
            @(posedge clk) wr_enable <= 1;
            wr_addr <= i;
            wr_data <= i;
            @(posedge clk) wr_enable <= 0;
        end
        @(posedge clk) rd0_enable <= 1;
        rd1_enable <= 1;
        wr_enable <= 1;
        rd0_addr <= 2;
        rd1_addr <= 3;
        wr_addr <= 4;   // r4 := r2 + r3;
        @(posedge clk) begin
            wr_enable <= 0;
            rd0_enable <= 0;
            rd1_enable <= 0;
        end

        @(posedge clk) begin
            rd0_addr <= 2;
            rd1_addr <= 7;
            wr_addr <= 2;   // r2 := r2 + r7;
            rd0_enable <= 1;
            rd1_enable <= 1;
        end
        @(posedge clk) wr_enable <= 1;
        @(posedge clk) begin
            wr_enable <= 0;
        end

        #10;
    end
endmodule
