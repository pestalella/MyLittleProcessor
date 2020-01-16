`ifndef PWM_DRIVER_SV
`define PWM_DRIVER_SV

module pwm_driver(
    input wire clk,
    input wire reset,
    input wire set_cutoff_en,
    input wire [7:0] cutoff_value,
    output wire pwm_out
);

parameter PWM_PERIOD = 7'd1;   // divide input freq by 100
parameter PWM_HALF_PERIOD = PWM_PERIOD/2;
bit clk_pwm;
bit [7:0] pwm_clk_counter = 0;

bit [7:0] cutoff;
bit [7:0] counter;
bit out;

assign pwm_out = out;

always @(posedge clk) begin
    if (reset) begin
        pwm_clk_counter <= '0;

        cutoff <= 'h7f;
        counter <= '0;
        out = 0;
    end else if (set_cutoff_en) begin
        cutoff <= cutoff_value;
        counter <= 0;
    end else
        pwm_clk_counter <= (pwm_clk_counter > PWM_PERIOD-1)? 0 : pwm_clk_counter + 1;
end

assign clk_pwm = pwm_clk_counter > PWM_HALF_PERIOD? 1 : 0;

always @(posedge clk_pwm) begin
    if (counter < cutoff) begin
        out <= 1;
    end else begin
        out <= 0;
    end
    counter <= counter + 1;
end

endmodule

`endif