`timescale 1ns / 1ps
`default_nettype none

module synth(
	input CLK,
	input BTN_N,
	output DA_MCLK,
	output DA_LRCK,
	output DA_SCLK,
	output DA_SDIN,
	input wire [1:0]waveform,
	input wire [7:0]velocity,
	input wire [7:0]pitch,
	input wire gate

);


reg [15:0] dds_signal;
initial dds_signal = 0;
reg rst;
wire wb_i2s_out_stall_o;
wire wb_i2s_out_ack_o;
reg wb_i2s_out_stb_i;
wb_i2s_out wb_i2s_out_instance(
	.clk(CLK), 
	.rst(rst), 
	.wb_cyc_i(), 
	.wb_stb_i(wb_i2s_out_stb_i), 
	.wb_data_i(amp_signal_out), 
	.wb_stall_o(wb_i2s_out_stall_o),
	.wb_ack_o(wb_i2s_out_ack_o),
	.i2s_mclk_o(DA_MCLK),
	.i2s_sclk_o(DA_SCLK),
	.i2s_lrck_o(DA_LRCK),
	.i2s_dout_o(DA_SDIN)
	);

//Amp
reg amp_stb;
wire amp_stall;
wire amp_ack;
wire [31:0] amp_signal_out;


amplifier amplifier_i(
	.clk(CLK),
	.rst(rst),

	.amplification({1'b0, velocity, 7'h00}),//(ad_envelope_o_env),//{midi_rx_instance_velocity, dip_sw }),

	.wb_stb_i(amp_stb),
	.wb_stall_o(amp_stall),
	.wb_ack_o(amp_ack),
	.audio_data_i({dds_signal, dds_signal}),
	// wb master out

	.wb_stb_o(wb_i2s_out_stb_i),
	.wb_stall_i(wb_i2s_out_stall_o),
	.wb_ack_i(wb_i2s_out_ack_o),
	.audio_data_o(amp_signal_out)


	);

wire [15:0] ad_envelope_o_env;
ad_envelope ad_envelope_instance(
	.i_clk(CLK),
	.i_gate(gate),
	.i_attack(8'h0f),
	.i_decay(8'h03),
	.o_env(ad_envelope_o_env)

);
wire [15:0] square_out;
wire [15:0] saw_out;
wire [15:0] triangle_out;
dds dds_instance(
	.clk(CLK),
	.square_out(square_out),
	.saw_out(saw_out),
	.triangle_out(triangle_out)
);


wire [15:0] lut_q;

// Pase accumulator
// clk = 12MHz -> 12MHz / 2^28 = 11.444Hz
reg [27:0] phase_acc;

initial phase_acc = 0;
wire [15:0] lut_pitch_value;
always @(posedge CLK)
begin
	phase_acc <= phase_acc + lut_pitch_value;
end

lut_dds lut_dds_instance(
	.clk(CLK),
	.r_address(phase_acc[27:16]),
	.q(lut_q)
);


lut_pitch lut_pitch_instance(
	.clk(CLK),
	.r_address(pitch[7:0]),
	.q(lut_pitch_value)
);

// signal routing

always @(posedge CLK)
begin
    if(waveform == 2'b00) begin
	dds_signal <= square_out;
    end
    else if (waveform == 2'b01) begin
	dds_signal <= saw_out;
    end
    else if (waveform == 2'b10) begin
	dds_signal <= triangle_out;
    end
    else begin
    	dds_signal <= lut_q;
    end
end


//very simple wb handling.
//initial amp_stb = 1'b0;
always @(posedge CLK)
begin
	if (~amp_stall & ~amp_stb)
		amp_stb <= 1'b1;
	else
		amp_stb <= 1'b0;
	
end

always @(posedge CLK)
	rst <= ~BTN_N;

endmodule

