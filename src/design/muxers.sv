`ifndef MUXERS_SV
`define MUXERS_SV

module reg_mux2to1 #(parameter DATA_BITS = 8) (
    input sel,
    input wire [DATA_BITS-1:0] in0,
    input wire [DATA_BITS-1:0] in1,
    output wire [DATA_BITS-1:0] out
    );

    assign out = (sel == 'b0)? in0 : in1;
endmodule

module reg_mux4to1 #(parameter DATA_BITS = 8) (
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

module reg_mux8to1 #(parameter DATA_BITS = 8) (
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
    assign out = (sel == 'b000)? in0 :
                ((sel == 'b001)? in1 :
                ((sel == 'b010)? in2 :
                ((sel == 'b011)? in3 :
                ((sel == 'b100)? in4 :
                ((sel == 'b101)? in5 :
                ((sel == 'b110)? in6 :
                                 in7))))));
endmodule

module reg_demux1to8 #(parameter DATA_BITS = 8) (
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
    always @(sel or in) begin
        out0 <= {DATA_BITS{1'bz}};
        out1 <= {DATA_BITS{1'bz}};
        out2 <= {DATA_BITS{1'bz}};
        out3 <= {DATA_BITS{1'bz}};
        out4 <= {DATA_BITS{1'bz}};
        out5 <= {DATA_BITS{1'bz}};
        out6 <= {DATA_BITS{1'bz}};
        out7 <= {DATA_BITS{1'bz}};
        case (sel)
            'b000: out0 <= in;
            'b001: out1 <= in;
            'b010: out2 <= in;
            'b011: out3 <= in;
            'b100: out4 <= in;
            'b101: out5 <= in;
            'b110: out6 <= in;
            'b111: out7 <= in;
        endcase
    end
endmodule

`endif