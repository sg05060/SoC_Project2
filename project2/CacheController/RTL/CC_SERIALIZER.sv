// Copyright (c) 2022 Sungkyunkwan University

module CC_SERIALIZER
(
	input	wire				clk,
	input	wire				rst_n,

	input	wire				fifo_empty_i,
	input	wire				fifo_aempty_i,
	input	wire	[517:0]		fifo_rdata_i,
	output	wire				fifo_rden_o,

    output  wire    [63:0]		rdata_o,
    output  wire            	rlast_o,
    output  wire            	rvalid_o,
    input   wire            	rready_i
);

	// Fill the code here
	reg	[63:0]	rdata;
	reg			rlast;
	reg			rvalid;
	reg [2:0]	offset;

	reg	[2:0]	index, index_n;


	 always_ff @(posedge clk)
        if (!rst_n) begin
            index	<= 0;
        end
        else if(rready_i && (!rlast)) begin
			index 	<= index_n;
		end else begin
			index	<= 0;
		end

	always_comb 
	begin
       	rvalid 		= !fifo_empty_i;
		offset		= fifo_rdata_i[517-:3];
		index_n		= index;
		rlast  		= 1'b0;
		case (index+offset) 
				3'b000: begin
					rdata	= fifo_rdata_i[511-:64];
				end
				3'b001: begin
					rdata	= fifo_rdata_i[447-:64];
				end
				3'b010: begin
					rdata	= fifo_rdata_i[383-:64];
				end
				3'b011: begin
					rdata	= fifo_rdata_i[319-:64];
				end
				3'b100: begin
					rdata	= fifo_rdata_i[255-:64];
				end
				3'b101: begin
					rdata	= fifo_rdata_i[191-:64];
				end
				3'b110: begin
					rdata	= fifo_rdata_i[127-:64];
				end
				3'b111: begin
					rdata	= fifo_rdata_i[63-:64];
				end
				default : begin
					rdata 	= {(64){1'b0}};
				end
		endcase
		
		if(rready_i && rvalid) begin
			index_n 	= index + 1;
			rlast		= (0 == index_n) ? 1 : 0;
		end
	end

	assign rvalid_o		= rvalid;
	assign rdata_o		= rdata;
	assign rlast_o		= rlast;
	assign fifo_rden_o 	= rlast;

endmodule
