`ifndef MUXERS_SV
`define MUXERS_SV

module mux2to1 #(parameter DATA_BITS = 8) (
    input sel,
    input wire [DATA_BITS-1:0] in0,
    input wire [DATA_BITS-1:0] in1,
    output wire [DATA_BITS-1:0] out
    );

    assign out = (sel == 'b0)? in0 : in1;
endmodule

module mux4to1 #(parameter DATA_BITS = 8) (
    input [1:0] sel,
    input wire [DATA_BITS-1:0] in0,
    input wire [DATA_BITS-1:0] in1,
    input wire [DATA_BITS-1:0] in2,
    input wire [DATA_BITS-1:0] in3,
    output wire [DATA_BITS-1:0] out
    );
    assign out = (sel == 'b00)? in0 :
                ((sel == 'b01)? in1 :
                ((sel == 'b10)? in2 :
                                in3));
endmodule

module mux8to1 #(parameter DATA_BITS = 8) (
    input [2:0] sel,
    input wire [DATA_BITS-1:0] in0,
    input wire [DATA_BITS-1:0] in1,
    input wire [DATA_BITS-1:0] in2,
    input wire [DATA_BITS-1:0] in3,
    input wire [DATA_BITS-1:0] in4,
    input wire [DATA_BITS-1:0] in5,
    input wire [DATA_BITS-1:0] in6,
    input wire [DATA_BITS-1:0] in7,
    output wire [DATA_BITS-1:0] out
    );
    bit[DATA_BITS-1:0] low_sel;
    mux4to1 #(.DATA_BITS(DATA_BITS)) low_half(
        .sel(sel[1:0]),
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .out(low_sel)
    );
    bit[DATA_BITS-1:0] high_sel;
    mux4to1 #(.DATA_BITS(DATA_BITS)) high_half(
        .sel(sel[1:0]),
        .in0(in4),
        .in1(in5),
        .in2(in6),
        .in3(in7),
        .out(high_sel)
    );
    mux2to1 #(.DATA_BITS(DATA_BITS)) out_mux(
        .sel(sel[2]),
        .in0(low_sel),
        .in1(high_sel),
        .out(out));
endmodule

module mux16to1 #(parameter DATA_BITS = 8) (
    input [3:0] sel,
    input wire [DATA_BITS-1:0] in0,
    input wire [DATA_BITS-1:0] in1,
    input wire [DATA_BITS-1:0] in2,
    input wire [DATA_BITS-1:0] in3,
    input wire [DATA_BITS-1:0] in4,
    input wire [DATA_BITS-1:0] in5,
    input wire [DATA_BITS-1:0] in6,
    input wire [DATA_BITS-1:0] in7,

    input wire [DATA_BITS-1:0] in8,
    input wire [DATA_BITS-1:0] in9,
    input wire [DATA_BITS-1:0] in10,
    input wire [DATA_BITS-1:0] in11,
    input wire [DATA_BITS-1:0] in12,
    input wire [DATA_BITS-1:0] in13,
    input wire [DATA_BITS-1:0] in14,
    input wire [DATA_BITS-1:0] in15,

    output wire [DATA_BITS-1:0] out
    );
    bit[DATA_BITS-1:0] low_sel;
    mux8to1 #(.DATA_BITS(DATA_BITS)) low_half(
        .sel(sel[2:0]),
        .in0(in0),
        .in1(in1),
        .in2(in2),
        .in3(in3),
        .in4(in4),
        .in5(in5),
        .in6(in6),
        .in7(in7),
        .out(low_sel)
    );
    bit[DATA_BITS-1:0] high_sel;
    mux8to1 #(.DATA_BITS(DATA_BITS)) high_half(
        .sel(sel[2:0]),
        .in0(in8),
        .in1(in9),
        .in2(in10),
        .in3(in11),
        .in4(in12),
        .in5(in13),
        .in6(in14),
        .in7(in15),
        .out(high_sel)
    );
    mux2to1 #(.DATA_BITS(DATA_BITS)) out_mux(
        .sel(sel[3]),
        .in0(low_sel),
        .in1(high_sel),
        .out(out));
endmodule

module demux1to8 #(parameter DATA_BITS = 8) (
    input bit [2:0] sel,
    input logic [DATA_BITS-1:0] in,
    output logic [DATA_BITS-1:0] out0,
    output logic [DATA_BITS-1:0] out1,
    output logic [DATA_BITS-1:0] out2,
    output logic [DATA_BITS-1:0] out3,
    output logic [DATA_BITS-1:0] out4,
    output logic [DATA_BITS-1:0] out5,
    output logic [DATA_BITS-1:0] out6,
    output logic [DATA_BITS-1:0] out7
    );

    assign out0 = (sel == 'b000) ? in : {DATA_BITS{1'bz}};
    assign out1 = (sel == 'b001) ? in : {DATA_BITS{1'bz}};
    assign out2 = (sel == 'b010) ? in : {DATA_BITS{1'bz}};
    assign out3 = (sel == 'b011) ? in : {DATA_BITS{1'bz}};
    assign out4 = (sel == 'b100) ? in : {DATA_BITS{1'bz}};
    assign out5 = (sel == 'b101) ? in : {DATA_BITS{1'bz}};
    assign out6 = (sel == 'b110) ? in : {DATA_BITS{1'bz}};
    assign out7 = (sel == 'b111) ? in : {DATA_BITS{1'bz}};
endmodule

module demux1to16 #(parameter DATA_BITS = 8) (
    input bit [3:0] sel,
    input logic [DATA_BITS-1:0] in,
    output logic [DATA_BITS-1:0] out0,
    output logic [DATA_BITS-1:0] out1,
    output logic [DATA_BITS-1:0] out2,
    output logic [DATA_BITS-1:0] out3,
    output logic [DATA_BITS-1:0] out4,
    output logic [DATA_BITS-1:0] out5,
    output logic [DATA_BITS-1:0] out6,
    output logic [DATA_BITS-1:0] out7,
    output logic [DATA_BITS-1:0] out8,
    output logic [DATA_BITS-1:0] out9,
    output logic [DATA_BITS-1:0] out10,
    output logic [DATA_BITS-1:0] out11,
    output logic [DATA_BITS-1:0] out12,
    output logic [DATA_BITS-1:0] out13,
    output logic [DATA_BITS-1:0] out14,
    output logic [DATA_BITS-1:0] out15
    );

    assign  out0 = (sel == 'b0000) ? in : {DATA_BITS{1'bz}};
    assign  out1 = (sel == 'b0001) ? in : {DATA_BITS{1'bz}};
    assign  out2 = (sel == 'b0010) ? in : {DATA_BITS{1'bz}};
    assign  out3 = (sel == 'b0011) ? in : {DATA_BITS{1'bz}};
    assign  out4 = (sel == 'b0100) ? in : {DATA_BITS{1'bz}};
    assign  out5 = (sel == 'b0101) ? in : {DATA_BITS{1'bz}};
    assign  out6 = (sel == 'b0110) ? in : {DATA_BITS{1'bz}};
    assign  out7 = (sel == 'b0111) ? in : {DATA_BITS{1'bz}};
    assign  out8 = (sel == 'b1000) ? in : {DATA_BITS{1'bz}};
    assign  out9 = (sel == 'b1001) ? in : {DATA_BITS{1'bz}};
    assign out10 = (sel == 'b1010) ? in : {DATA_BITS{1'bz}};
    assign out11 = (sel == 'b1011) ? in : {DATA_BITS{1'bz}};
    assign out12 = (sel == 'b1100) ? in : {DATA_BITS{1'bz}};
    assign out13 = (sel == 'b1101) ? in : {DATA_BITS{1'bz}};
    assign out14 = (sel == 'b1110) ? in : {DATA_BITS{1'bz}};
    assign out15 = (sel == 'b1111) ? in : {DATA_BITS{1'bz}};
endmodule

`endif
