`default_nettype none

module lut_pitch#(
	parameter WIDTH = 16,
	parameter DEPTH = 7,
)

(
	input wire clk,
	input wire [DEPTH-1:0] r_address,
	output reg [15:0] q
);


// BRAM
reg [WIDTH-1:0] q_pitch_bram [0:((2**DEPTH)-1)];
initial $readmemh("./../lut/lut_pitch.hex", q_pitch_bram);
always @(posedge clk)
begin
	q <= q_pitch_bram[r_address];
end

endmodule
