
`timescale 1ns / 1ps
`default_nettype none



// Stereo amp

module amplifier
(
	input	wire	clk,
	input	wire	rst,


	input	wire	[15:0]	amplification,



	// wb slave in interface

	input	wire		wb_stb_i,
	output	reg		wb_stall_o,
	output	reg		wb_ack_o,
	input	wire		[31:0]	audio_data_i,

	// wb master out

	output reg 	wb_stb_o,
	input	wire 	wb_stall_i,
	input 	wire 	wb_ack_i,
	output	reg 	[31:0]	audio_data_o

);



localparam [3:0]
	state_register_left_and_idle = 4'b0001,
	state_register_right_and_read_out_left = 4'b0010,
	state_read_out_right = 4'b0100,
	state_pass_out = 4'b1000;

reg [15:0] A; // multiplier input
wire [15:0] B;
assign B = amplification;
wire [31:0] O; //

reg [15:0] audio_data_buffer = 0; 
// State machine Combinatory Logic
// controls input to Register A of DSP block
reg [3:0] state;

always @* begin
	case(state)
		state_register_left_and_idle:
			A = audio_data_i[31:16];
		state_register_right_and_read_out_left:
			A = audio_data_buffer;
		default:
			A = 16'h0000;
	endcase
end




initial state = state_register_left_and_idle;
initial wb_stall_o = 1'b0;
initial audio_data_buffer = 16'h0000;
initial audio_data_o = 16'h0000;
initial wb_ack_o = 1'b0;
initial wb_stb_o = 1'b0;
initial wb_stall_o = 1'b0;



// Sequential logic. Wishbone logic and state progression
always @(posedge clk) begin
	 	if (wb_stb_i && !wb_stall_o) begin
			wb_stall_o <= 1'b1;
			audio_data_buffer <= audio_data_i[15:0]; // read right to buffer. left channel is read to mul reg A
			state <= state_register_right_and_read_out_left;
			wb_ack_o <= 1'b1;
		end else if (state == state_register_right_and_read_out_left)
		begin
			wb_ack_o <= 1'b0;
			audio_data_o [31:16] <= O [31:16];
			state <= state_read_out_right;
		end else if (state == state_read_out_right)
		begin
			audio_data_o [15:0] <= O[31:16];

			state <= state_pass_out;
		end else if (state == state_pass_out)
		begin
			// handle wb master
			if(!wb_stall_i)
				wb_stb_o <= 1'b1;
			if(wb_stb_o)
				wb_stb_o <= 1'b0;
			if(wb_ack_i)
			begin
				wb_stall_o <= 1'b0;
				state <= state_register_left_and_idle;
			end
		end
end





SB_MAC16 #(
    .NEG_TRIGGER(1'b0),
    .C_REG(1'b0),
    .A_REG(1'b0),
    .B_REG(1'b0),
    .D_REG(1'b0),
    .TOP_8x8_MULT_REG(1'b0),
    .BOT_8x8_MULT_REG(1'b0),
    .PIPELINE_16x16_MULT_REG1(1'b0),
    .PIPELINE_16x16_MULT_REG2(1'b1),
    .TOPOUTPUT_SELECT(2'b11),
    .TOPADDSUB_LOWERINPUT(2'b00),
    .TOPADDSUB_UPPERINPUT(1'b0),
    .TOPADDSUB_CARRYSELECT(2'b00),
    .BOTOUTPUT_SELECT(2'b11),
    .BOTADDSUB_LOWERINPUT(2'b00),
    .BOTADDSUB_UPPERINPUT(1'b0),
    .BOTADDSUB_CARRYSELECT(2'b00),
    .MODE_8x8(1'b0),
    .A_SIGNED(1'b1),
    .B_SIGNED(1'b0)
) i_sbmac16 (
    .A(A),
    .AHOLD(1'b1),
    .B(B),
    .BHOLD(1'b1),
    .C(16'h0000),
    .D(16'h0000),
    .CHOLD(1'b0),
    .DHOLD(1'b0),

    .IRSTTOP                    (1'b0), //keep hold register in reset
    .IRSTBOT                    (1'b0), //keep hold register in reset
    .ORSTTOP                    (1'b0), //keep hold register in reset
    .ORSTBOT                    (1'b0), //keep hold register in reset
    .OLOADTOP                   (1'b0), //keep unused signals quiet
    .OLOADBOT                   (1'b0), //keep unused signals quiet
    .ADDSUBTOP                  (1'b0), //unused
    .ADDSUBBOT                  (1'b0), //unused
    .OHOLDTOP                   (1'b0), //keep hold register stable
    .OHOLDBOT                   (1'b0), //keep hold register stable

    .CE(1'b1),
    .CLK(clk),

    // .CO(1'b0), .ACCUMCO(1'b0), .SIGNEXTOUT(1'b0),
    .CI(1'b0), .ACCUMCI(1'b0), .SIGNEXTIN(1'b0),
    .O(O)
);


endmodule
