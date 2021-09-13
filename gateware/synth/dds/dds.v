/*
tutorial: https://www.fpga4fun.com/DDS1.html
*/

`timescale 1ns / 1ps
`default_nettype none


module dds(
input wire clk,
output wire [15:0] square_out,
output wire [15:0] saw_out,
output wire [15:0] triangle_out

); 

// this parameter has to be the same as in the dac module (wb_i2s_out.v)
parameter LR_CLK_DIVIDER = 256;

// assumtion clk is 12MHz
// 14bit -> 12MHz / 16384 = 732.421

parameter MSB_CNT = 13;
reg [MSB_CNT:0] cnt;
initial cnt = 0;
always @(posedge clk)
	cnt <= cnt + 1;
// create max amplitude with 2nd complement.

// Square
assign square_out = {~cnt[MSB_CNT],{15{cnt[MSB_CNT]}}};

// Saw
assign saw_out = {cnt, cnt[0], cnt[0]};

// Triangle
assign triangle_out = ~cnt[MSB_CNT] ? {~cnt[MSB_CNT-1],cnt[MSB_CNT-2:0],{3{cnt[0]}}} : ~{~cnt[MSB_CNT-1],cnt[MSB_CNT-2:0],{3{cnt[0]}}};
endmodule
