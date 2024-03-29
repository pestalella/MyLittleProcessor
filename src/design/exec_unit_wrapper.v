module exec_unit_wrapper(
    input wire clk,
    input wire reset_n,

    output wire pwm_out0,
    output wire pwm_out1,
    output wire pwm_out2,
    output wire pwm_out3
);
    cpu_top u_top(
        .clk(clk),
        .reset_n(reset_n),
        .pwm_out0(pwm_out0),
        .pwm_out1(pwm_out1),
        .pwm_out2(pwm_out2),
        .pwm_out3(pwm_out3)
    );
endmodule
