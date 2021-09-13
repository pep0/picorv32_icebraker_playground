
`timescale 1ns / 1ps
`default_nettype none

module ad_envelope(
	input wire i_clk,
	input wire i_gate,
	input wire [7:0] i_attack,
	input wire [7:0] i_decay,
	output wire [15:0] o_env

);



localparam IDLE = 4'h0,
	ATTACK = 4'h1,
	DECAY = 4'h2;


reg [3:0] state;
initial state = 4'h0;

always @(posedge i_clk)
begin
	case(state)
	IDLE:
		if(i_gate)
			state <= ATTACK;
	ATTACK:
		if(!i_gate || (o_env == 16'hFFFF))
			state <= DECAY;
	DECAY:
		if((o_env == 16'h0000))
			state <= IDLE;
		else if(!i_gate)
			state <= IDLE;
	endcase
end


reg [25:0] env_counter;
initial env_counter = 0;

assign o_env = env_counter[25:10];

always @(posedge i_clk)
begin
	case(state)
	IDLE:
		env_counter <= 26'h0000000;
	ATTACK:
		env_counter <= env_counter + i_attack;
	DECAY:
		env_counter <= env_counter - i_decay;
	endcase
end


endmodule
