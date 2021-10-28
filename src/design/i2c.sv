`ifndef I2C_SV
`define I2C_SV

// I2C module. It will

module i2c (
    input wire ck_scl,
    input wire ck_sda,
    output wire led0,
    output wire led1
);

logic start_detected_r;
logic stop_detected_r;

assign led0 = start_detected_r;
assign led1 = stop_detected_r;

initial begin
    start_detected_r = 0;
    stop_detected_r = 0;
end

always_ff @(negedge ck_sda) begin
    if (ck_scl) begin
        start_detected_r = ~start_detected_r;
    end
end

always_ff @(posedge ck_sda) begin
    if (ck_scl) begin
        stop_detected_r = ~stop_detected_r;
    end
end

endmodule

`endif