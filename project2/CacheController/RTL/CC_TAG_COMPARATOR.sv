// Copyright (c) 2022 Sungkyunkwan University

module CC_TAG_COMPARATOR
(
	input	wire			clk,
	input	wire			rst_n,

	input	wire	[16:0]	tag_i,
	input	wire	[8:0]	index_i,
	input   wire	[5:0]	offset_i,
	output	wire	[16:0]	tag_delayed_o,
	output	wire	[8:0]	index_delayed_o,
	output	wire	[5:0]	offset_delayed_o,

	input	wire			hs_pulse_i,

	input	wire	[17:0]	rdata_tag_i,

	output	wire			hit_o,
	output	wire			miss_o,

	// Used for hit_flag_write_en (Reorder unit)
	output 	wire			hs_pulse_delayed_o
);

	reg 	[16:0]	tag_delayed;
	reg		[8:0]	index_delayed;
	reg		[5:0]	offset_delayed;
	reg				hs_pulse_delayed;

	reg				hit;
	reg				miss;
	// Fill the code here
	always_ff @(posedge clk)
		if (!rst_n) begin
			tag_delayed			<= 1'b0;
			index_delayed 		<= 1'b0;
			offset_delayed		<= 1'b0;
			hs_pulse_delayed 	<= 1'b0;
		end	
		else begin
			tag_delayed			<= tag_i;
			index_delayed 		<= index_i;
			offset_delayed		<= offset_i;
			hs_pulse_delayed 	<= hs_pulse_i;
		end

	always_comb 
	begin
		hit						= 1'b0;
		miss					= 1'b0;
		if (hs_pulse_delayed) begin
			if (rdata_tag_i == tag_delayed) begin
				hit 			= 1'b1;
			end else begin
				miss 			= 1'b1;
			end
		end
	end

	assign	tag_delayed_o		= tag_delayed;
	assign	index_delayed_o		= index_delayed;
	assign	offset_delayed_o	= offset_delayed;
	assign	hit_o				= hit;
	assign 	miss_o				= miss;
	assign  hs_pulse_delayed_o	= hs_pulse_delayed;

endmodule
