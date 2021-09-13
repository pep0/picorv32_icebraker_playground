
/*
tutorial: https://www.fpga4fun.com/DDS1.html
*/

`timescale 1ns / 1ps
`default_nettype none

module lut_dds#(
	parameter WIDTH = 16,
	parameter DEPTH = 10,
)

(
	input wire clk,
	// r_address has 2 bits more than DEPTH because of 2 sine symetries
	input wire [DEPTH+ 1:0] r_address,
	output reg [15:0] q
);

// delay MSB of r_address for sign of output. 2 cycles. 
reg [1:0] r_address_msb_dly;
always @(posedge clk)
begin
	r_address_msb_dly[0] <= r_address[DEPTH+1];
	r_address_msb_dly[1] <= r_address_msb_dly[0];
end

// first symmetry of the sine signal
reg [9:0] sym1_address;
always @(posedge clk)
	sym1_address <= r_address[DEPTH] ? ~r_address[DEPTH-1:0]: r_address[DEPTH-1:0];

reg [15:0] ram_read;

// BRAM
reg [WIDTH-1:0] q_sine_bram [0:((2**DEPTH)-1)];
initial $readmemh("./../lut/lut_sin_16w_10d.hex", q_sine_bram);
always @(posedge clk)
begin
	ram_read <= q_sine_bram[sym1_address];
end

// second symmetry of sine. RAM readout is delayed by two cycles. therefore
// the r_address_msb_dly was also delayed two cycles. 
always @(posedge clk)
	q <= r_address_msb_dly[1] ? {1'b1, ~ram_read[14:0]} : {1'b0, ram_read[14:0]} ;

endmodule
