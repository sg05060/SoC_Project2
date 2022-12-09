// Copyright (c) 2022 Sungkyunkwan University

module CC_DATA_REORDER_UNIT
(
    input   wire            clk,
    input   wire            rst_n,
	
    // AMBA AXI interface between MEM and CC (R channel)
    input   wire    [63:0]  mem_rdata_i,
    input   wire            mem_rlast_i,
    input   wire            mem_rvalid_i,
    output  wire            mem_rready_o,    

    // Hit Flag FIFO write interface
    output  wire            hit_flag_fifo_afull_o,
    input   wire            hit_flag_fifo_wren_i,
    input   wire            hit_flag_fifo_wdata_i,

    // Hit data FIFO write interface
    output  wire            hit_data_fifo_afull_o,
    input   wire            hit_data_fifo_wren_i,
    input   wire    [517:0] hit_data_fifo_wdata_i,

	// AMBA AXI interface between INCT and CC (R channel)
    output  wire    [63:0]  inct_rdata_o,
    output  wire            inct_rlast_o,
    output  wire            inct_rvalid_o,
    input   wire            inct_rready_i
);

    // Fill the code here
    localparam  HIT_FLAG_FIFO_WIDTH                     = 1;
    localparam  HIT_FLAG_FIFO_DEPTH                     = 16;
    localparam  HIT_FLAG_FIFO_AFULL_THRESHOLD           = 13;
    localparam  HIT_FLAG_FIFO_AEMPTY_THRESHOLD          = 0;

    localparam  HIT_DATA_OFFSET_FIFO_WIDTH              = 32;
    localparam  HIT_DATA_OFFSET_FIFO_DEPTH              = 16;
    localparam  HIT_DATA_OFFSET_FIFO_AFULL_THRESHOLD    = 13;
    localparam  HIT_DATA_OFFSET_FIFO_AEMPTY_THRESHOLD   = 0;

    //  Hit Flag FIFO read interface
    reg     hit_flag_fifo_rden_o;
    wire    hit_flag_fifo_rdata_o;
    wire    hit_flag_fifo_empty_o; // This mean valid of hit_flag_fifo_rdata

    // Serializer signals
    wire            serial_rvalid_i; 
    wire    [63:0]  serial_rdata_i;
    wire            serial_rlast_i;
    reg             serial_rready_o;

    // INCT R ch
    reg             inct_rvalid;
    reg [63:0]      inct_rdata;
    reg             inct_rlast;

    // Hit data/offset fifo
    wire            hit_data_fifo_rden_o;
    wire [517:0]    hit_data_fifo_rdata_o;
    wire            hit_data_fifo_empty_o;

    // MC R ch
    reg             mem_rready;
    
    always_comb 
	begin
        inct_rvalid         = 1'b0;
        inct_rlast          = 1'b0;
        inct_rdata          = {(64){1'b0}};
        
        serial_rready_o     = 1'b0;
        mem_rready          = 1'b0;

        hit_flag_fifo_rden_o = 1'b0;

        if(!hit_flag_fifo_empty_o) begin
            if(hit_flag_fifo_rdata_o) begin // hit data from Serializer
                serial_rready_o    = 1'b1;
                //if(serial_rvalid_i)
                inct_rdata  = serial_rdata_i;
                inct_rlast  = serial_rlast_i;
                inct_rvalid = serial_rvalid_i && serial_rready_o;
                if(inct_rlast && inct_rvalid && inct_rready_i)
                        hit_flag_fifo_rden_o = 1'b1;
            end
            else begin
                    mem_rready = 1'b1;
                //if(mem_rvalid_i) begin
                    inct_rdata  = mem_rdata_i;
                    inct_rlast  = mem_rlast_i;
                    inct_rvalid = (mem_rready && mem_rvalid_i);
                    if(inct_rlast && inct_rvalid && inct_rready_i)
                        hit_flag_fifo_rden_o = 1'b1;
                //end
            end
        end
	end


    CC_FIFO#(
        .FIFO_DEPTH       ( HIT_FLAG_FIFO_DEPTH ),
        .DATA_WIDTH       ( HIT_FLAG_FIFO_WIDTH ),
        .AFULL_THRESHOLD  ( HIT_FLAG_FIFO_AFULL_THRESHOLD ),
        .AEMPTY_THRESHOLD ( HIT_FLAG_FIFO_AEMPTY_THRESHOLD )
    )Hit_Flag_FIFO(
        .clk             ( clk                      ),
        .rst_n           ( rst_n                    ),
        .full_o          (                          ),
        .afull_o         ( hit_flag_fifo_afull_o    ),
        .wren_i          ( hit_flag_fifo_wren_i     ),
        .wdata_i         ( hit_flag_fifo_wdata_i    ),
        .empty_o         ( hit_flag_fifo_empty_o    ),
        .aempty_o        ( hit_flag_fifo_aempty_o   ),
        .rden_i          ( hit_flag_fifo_rden_o     ),
        .rdata_o         ( hit_flag_fifo_rdata_o    )
    );

    CC_FIFO#(
        .FIFO_DEPTH      ( HIT_DATA_OFFSET_FIFO_DEPTH ),
        .DATA_WIDTH      ( HIT_DATA_OFFSET_FIFO_WIDTH ),
        .AFULL_THRESHOLD ( HIT_DATA_OFFSET_FIFO_AFULL_THRESHOLD ),
        .AEMPTY_THRESHOLD ( HIT_DATA_OFFSET_FIFO_AEMPTY_THRESHOLD )
    )Hit_Data_Offset_FIFO(
        .clk             ( clk                      ),
        .rst_n           ( rst_n                    ),
        .full_o          (                          ),
        .afull_o         ( hit_data_fifo_afull_o    ),
        .wren_i          ( hit_data_fifo_wren_i     ),
        .wdata_i         ( hit_data_fifo_wdata_i    ),
        .empty_o         ( hit_data_fifo_empty_o    ),
        .aempty_o        (                          ),
        .rden_i          ( hit_data_fifo_rden_o     ),
        .rdata_o         ( hit_data_fifo_rdata_o    )
    );

    CC_SERIALIZER u_CC_SERIALIZER(
        .clk           ( clk                        ),
        .rst_n         ( rst_n                      ),
        .fifo_empty_i  ( hit_data_fifo_empty_o      ),
        .fifo_aempty_i (                            ),
        .fifo_rdata_i  ( hit_data_fifo_rdata_o      ),
        .fifo_rden_o   ( hit_data_fifo_rden_o       ),
        .rdata_o       ( serial_rdata_i             ),
        .rlast_o       ( serial_rlast_i             ),
        .rvalid_o      ( serial_rvalid_i            ),
        .rready_i      ( serial_rready_o            )
    );

    assign mem_rready_o     = mem_rready;
    
    assign inct_rvalid_o    = inct_rvalid;
    assign inct_rdata_o     = inct_rdata;
    assign inct_rlast_o     = inct_rlast;


endmodule