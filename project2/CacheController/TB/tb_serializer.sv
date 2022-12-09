module tb_serializer();

    reg				    clk;
	reg				    rst_n;
	reg				    fifo_empty_i;
	reg				    fifo_aempty_i;
	reg	    [517:0]	    fifo_rdata_i;
    wire				fifo_rden_o;
    wire    [63:0]		rdata_o;
    wire            	rlast_o;
    wire            	rvalid_o;
    reg            	    rready_i;

    initial begin
        clk = 1'b0;
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        rst_n = 1'b0;
        fifo_aempty_i = 1'b1;
        fifo_empty_i = 1'b1;
        fifo_rdata_i = 518'b0;
        rready_i = 1'b0;

        repeat (2) 
            @(posedge clk);
        #1;
        rst_n = 1'b1;
       

        repeat (2) 
            @(posedge clk);
        #1;
        for(int i = 0; i < 65; i++) begin
            if(i == 0) begin
                fifo_rdata_i[517-:6] = 6'b010000;
            end else begin
                fifo_rdata_i[64*(9-i)-1-:64] = i;
            end
        end
        
        @(posedge clk);
        #1;
        rready_i = 1'b1;

        repeat (8) 
            @(posedge clk);
        #1;
        for(int i = 0; i < 65; i++) begin
            if(i == 0) begin
                fifo_rdata_i[517-:6] = 6'b001000;
            end else begin
                fifo_rdata_i[64*(9-i)-1-:64] = i+1;
            end
        end
        //rready_i = 1'b0;

    end

    CC_SERIALIZER u_CC_SERIALIZER(
        .clk           ( clk           ),
        .rst_n         ( rst_n         ),
        .fifo_empty_i  ( fifo_empty_i  ),
        .fifo_aempty_i ( fifo_aempty_i ),
        .fifo_rdata_i  ( fifo_rdata_i  ),
        .fifo_rden_o   ( fifo_rden_o   ),
        .rdata_o       ( rdata_o       ),
        .rlast_o       ( rlast_o       ),
        .rvalid_o      ( rvalid_o      ),
        .rready_i      ( rready_i      )
    );

endmodule