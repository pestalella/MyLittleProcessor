`ifndef PWM_DRIVER_SV
`define PWM_DRIVER_SV

`include "muxers.sv"

module pwm_driver(
    input wire clk,
    input wire reset,
    input wire set_cutoff_en,
    input wire [7:0] cutoff_value,
    output wire pwm_out
);

parameter PWM_PERIOD = 7'd100;   // divide input freq by 100
parameter PWM_HALF_PERIOD = PWM_PERIOD/2;
bit clk_pwm;
bit [7:0] pwm_clk_counter = 0;

bit [7:0] cutoff;
bit [7:0] counter;
bit [7:0] next_counter;
bit out;
enum bit {RESET, INCREASE} counter_input_sel;

assign pwm_out = out;

mux2to1 counter_input_mux(
    .sel(counter_input_sel),
    .in0('0),
    .in1(next_counter),
    .out(counter)
);

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        pwm_clk_counter   <= '0;
        counter_input_sel <= RESET;
        cutoff            <= 'h7f;
    end else if (set_cutoff_en) begin
        counter_input_sel <= RESET;
        cutoff            <= cutoff_value;
    end else begin
        counter_input_sel <= INCREASE;
        pwm_clk_counter   <= (pwm_clk_counter > PWM_PERIOD-1)? 0 : pwm_clk_counter + 1;
    end
    clk_pwm <= pwm_clk_counter > PWM_HALF_PERIOD? 1 : 0;
end

always_ff @(posedge clk_pwm) begin
    if (counter < cutoff) begin
        out <= 1;
    end else begin
        out <= 0;
    end
    next_counter <= counter + 1;
end

endmodule

`endif
