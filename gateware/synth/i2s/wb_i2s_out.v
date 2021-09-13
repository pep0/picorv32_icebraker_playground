
`timescale 1ns / 1ps
`default_nettype none

// wishbone slave
// i2s source master

// the idea:
// clk = 12MHz -> lr_clk = clk / 256 = ~48kHz
// sclk / lrck ratio = 64 (could also be 32.)

module wb_i2s_out
(
	// for the moment we asume clock is 25Mhz
	input	wire	clk,
	input	wire	rst,

	// wb slave interfaces
	// no address yet
	input 	wire 	wb_cyc_i,
	input	wire		wb_stb_i,
	//input	reg		wb_we_i,
	input	wire [31:0]	wb_data_i, //16bit left and 16bit right audio 
	output	reg 	wb_stall_o,
	output	reg		wb_ack_o,

	// i2s master inreface
	output	wire 	i2s_mclk_o,
	output	reg 	i2s_sclk_o,
	output	reg		i2s_lrck_o,
	output	reg		i2s_dout_o
);
	

	parameter LR_CLK_DIVIDER = 256;
	parameter AUDIO_BIT_WIDTH = 16;
	parameter SCLK_PER_LR = 64;
	parameter SCLK_DIVIDER = LR_CLK_DIVIDER/SCLK_PER_LR;
	

	// 1 clk cycle delay for lrck. See datasheet of DAC. 
	// lrck in Refrence guide is incorrectly inverted
	reg i2s_lrck_o_dly_reg;
	initial  i2s_lrck_o_dly_reg = 0;	
	always @(posedge clk)
		i2s_lrck_o <= i2s_lrck_o_dly_reg;

	// master clock 25MHz
	assign i2s_mclk_o = clk; 

	// data buffer left to right msb to lsb
	reg [2*AUDIO_BIT_WIDTH-1:0] data_buffer;
	

	// Generate SCLK (clk/8)
	// integer clock divider
	reg [5:0] sclk_cnt;
	reg [5:0] sclk_div_cnt;
	reg [5:0] sclk_cnt_prescaler;

	initial sclk_div_cnt = 0;
	initial sclk_cnt = 0;
	initial i2s_sclk_o = 1'b1;
	initial sclk_cnt_prescaler = 0;

	always @(posedge clk) begin
			// sclk_cnt with sclk_cnt_prescaler
			if (sclk_cnt_prescaler >= SCLK_DIVIDER-1) begin
				sclk_cnt_prescaler <= 0;
				if(sclk_cnt >= SCLK_PER_LR-1) begin
					sclk_cnt <= 0;
				end
				else begin
					sclk_cnt <= sclk_cnt + 1;
				end
			end
			else begin
				sclk_cnt_prescaler <= sclk_cnt_prescaler + 1;
			end
			// 
			if (sclk_div_cnt >= SCLK_DIVIDER/2-1) begin
				sclk_div_cnt <= 0;
				i2s_sclk_o <= !i2s_sclk_o;
			end else begin
				sclk_div_cnt <= sclk_div_cnt + 1;
			end
	end

	// Generate LRCLK
	// integer clock divider
	reg [9:0] lrclk_div_cnt;
	initial lrclk_div_cnt = 0;
	initial i2s_lrck_o_dly_reg = 0;

	always @(posedge clk) begin
		if (lrclk_div_cnt >= LR_CLK_DIVIDER/2-1) begin
			lrclk_div_cnt <= 0;
			i2s_lrck_o_dly_reg <= !i2s_lrck_o_dly_reg;
		end else begin
			lrclk_div_cnt <= lrclk_div_cnt + 1;
		end
	end

	// Generate rising sclk stb
	reg sclk_last;
	wire sclk_rising_stb;
	always @(posedge clk) begin
		sclk_last <= i2s_sclk_o;
	end

	assign sclk_rising_stb = (~sclk_last & i2s_sclk_o);


	// Take wb_data_in and shift it out to i2s_dout_o
	
	initial i2s_dout_o = 0;
	always @(posedge clk) begin
		if (sclk_rising_stb) begin

			if (sclk_cnt >= 1 && sclk_cnt <= AUDIO_BIT_WIDTH) begin
				// load left data
				// at rising edge of sclk load a data bite.
				// start with msb
				i2s_dout_o <= data_buffer[(2*AUDIO_BIT_WIDTH-1) - (sclk_cnt-1)];
			end else if (sclk_cnt >= (SCLK_PER_LR/2) + 1 && sclk_cnt <= (SCLK_PER_LR/2) + AUDIO_BIT_WIDTH) begin
				// load right data (start with bit 15 of data_buffer
				i2s_dout_o <= data_buffer[ (AUDIO_BIT_WIDTH-1) - ((sclk_cnt - 1) - (SCLK_PER_LR/2))];
			end else begin
				i2s_dout_o <= 0;
			end
		end
	end


	// Wishbone bus manager
	reg data_lock;
	
	initial wb_ack_o = 1'b0;
	initial wb_stall_o = 1'b0;
	initial data_buffer <= 0;
	initial data_lock <= 0;


	always @(posedge clk) begin
			if (wb_stb_i && (!wb_stall_o) && (!data_lock)) begin
				// Request
				data_buffer <= wb_data_i;
				wb_ack_o <= 1'b1;
				wb_stall_o <= 1'b1;
				data_lock <= 1'b1;
			end
			else if (sclk_cnt == ((SCLK_PER_LR/2 + AUDIO_BIT_WIDTH + 1)) && wb_stall_o && (!data_lock)) begin
				wb_stall_o <= 0;
				data_buffer <= 0;
			end
			else if (sclk_cnt == 1 && data_lock) begin
				data_lock <= 1'b0;
			end
			if (wb_ack_o) begin
				wb_ack_o <= 1'b0;
			end
	end

/*
*	Formal Verification
*/
`ifdef	FORMAL

	reg	f_past_valid;
	initial	f_past_valid = 0;
	always @(posedge clk)
		f_past_valid <= 1'b1;

	//////
	//
	// Bus properties
	//
	initial	assume(!wb_cyc_i);

	// i_stb is only allowed if i_cyc is also true
	always @(*)
	if (!wb_cyc_i)
		assume(!wb_stb_i);

	// When i_cyc goes high, so too should i_stb
	// Since this is an assumption, no f_past_valid is required
	always @(posedge clk )
	if ((!$past(wb_cyc_i))&&(wb_cyc_i))
		assume(wb_stb_i);

	always @(posedge clk)
	if (($past(wb_stb_i))&&($past(wb_stall_o)))
	begin
		assume(wb_stb_i);
		//assume(i_we == $past(i_we));
		//assume(i_addr == $past(i_addr));
		//if (i_we)
		//	assume(i_data == $past(i_data));
	end

	always @(posedge clk)
	if ((f_past_valid)&&($past(wb_stb_i))&&(!$past(wb_stall_o))&&(!$past(data_lock)))
		assert(wb_ack_o);


`endif
endmodule
