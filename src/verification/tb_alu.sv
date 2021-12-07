`timescale 1ns / 1ps

module tb_alu();
    logic clk;

    always begin
        #5 clk = !clk;
    end

    logic [7:0] a;
    logic [7:0] b;
    logic cin;

    logic [7:0] result;
    logic cout;

    alu dut(.a(a), .b(b), .cin(cin),
            .result(result), .cout(cout));

    initial begin
        @(posedge clk) begin
            a <= 0;
            b <= 0;
            cin <= 0;
            result <= 0;
            cout <= 0;
        end
        @(posedge clk) begin
            a = 37;
            b = 5;
        end
        @(posedge clk) begin
            cin = 1;
        end
        @(posedge clk) begin
            cin = 0;
            a = 255;
            b = 1;
        end
    end


endmodule
