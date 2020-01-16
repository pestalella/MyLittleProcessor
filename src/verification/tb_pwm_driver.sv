`include "pwm_driver.sv"

module tb_pwm_driver();
    bit clk;
    bit reset;
    bit set_cutoff_en;
    bit [7:0] cutoff_value;
    bit [7:0] counter;
    bit pwm_out;

    pwm_driver dut(
        .clk(clk),
        .reset(reset),
        .set_cutoff_en(set_cutoff_en),
        .cutoff_value(cutoff_value),
        .pwm_out(pwm_out)
    );

    always begin
        #5 clk = ~clk;
    end
    
    always @(posedge clk)
        counter += 1;

    initial begin
        clk = 0;
        counter = 0;
        reset = 1;
        set_cutoff_en = 0;

        @(posedge clk) begin
            reset = 0;
            set_cutoff_en = 1;
            cutoff_value = 254;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 1;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 2;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 4;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 8;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 16;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 32;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 64;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);

        @(posedge clk) begin
            set_cutoff_en = 1;
            cutoff_value = 128;
        end
        @(posedge clk);
        set_cutoff_en = 0;
        repeat(512) @(posedge clk);
    end

endmodule