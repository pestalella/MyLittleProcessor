
module tb_pwm_driver();
    logic clk;
    logic reset_n;
    logic set_cutoff_en;
    logic [7:0] cutoff_value;
    logic [7:0] counter;
    logic pwm_out;

    pwm_driver dut(
        .clk(clk),
        .reset_n(reset_n),
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
        reset_n = 0;
        set_cutoff_en = 0;

        @(posedge clk) begin
            reset_n = 1;
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
