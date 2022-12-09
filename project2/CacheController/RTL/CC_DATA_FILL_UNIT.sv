// Copyright (c) 2022 Sungkyunkwan University

//*********************************************************//
// After work: tag data를 register로 저장하면, rden_o 신호를 
//             wren가 아닌 last에 맞춰 한 cycle 줄일수 있다.
//*********************************************************//            
module CC_DATA_FILL_UNIT
(
    input   wire            clk,
    input   wire            rst_n,
	
    // AMBA AXI interface between MEM and CC (R channel)
    input   wire    [63:0]  mem_rdata_i,
    input   wire            mem_rlast_i,
    input   wire            mem_rvalid_i,
    input   wire            mem_rready_i,

    // Miss Addr FIFO read interface 
    input   wire            miss_addr_fifo_empty_i,
    input   wire    [31:0]  miss_addr_fifo_rdata_i,
    output  wire            miss_addr_fifo_rden_o,

    // SRAM write port interface
    output  wire                wren_o,
    output  wire    [8:0]       waddr_o,
    output  wire    [17:0]      wdata_tag_o,
    output  wire    [511:0]     wdata_data_o
);

    // Fill the code here
    reg             [8:0]       waddr;
    reg             [17:0]      wdata_tag;
    reg             [5:0]       offset;
    reg                         wren, wren_n;
    
    reg             [511:0]     data_buffer;
    reg             [2:0]       cnt, cnt_n;
    reg             [2:0]       wptr;

    always_ff @(posedge clk)
        if (!rst_n) begin
            cnt             <= 3'b0; 
            data_buffer     <= 448'b0;
            wren            <= 1'b0;
        end else if(mem_rvalid_i && mem_rready_i) begin
            wren            <= wren_n;
            cnt             <= cnt_n;
            case(wptr)
                3'b000: begin
                    data_buffer[511-:64] = mem_rdata_i;
                end
                3'b001: begin
                    data_buffer[447-:64] = mem_rdata_i;
                end
                3'b010: begin
                    data_buffer[383-:64] = mem_rdata_i;
                end
                3'b011: begin
                    data_buffer[319-:64] = mem_rdata_i;
                end
                3'b100: begin
                    data_buffer[255-:64] = mem_rdata_i;
                end
                3'b101: begin
                    data_buffer[191-:64] = mem_rdata_i;
                end
                3'b110: begin
                    data_buffer[127-:64] = mem_rdata_i;
                end
                3'b111: begin
                    data_buffer[63-:64] = mem_rdata_i;
                end
            endcase
        end
        


    always_comb 
    begin
        waddr       = miss_addr_fifo_rdata_i[14-:9];
        wdata_tag   = {1'b1, miss_addr_fifo_rdata_i[31-:17]};
        offset      = miss_addr_fifo_rdata_i[5-:6];
        
        wren_n      = wren;
        cnt_n       = cnt;

        wptr        = cnt + offset;

        if(mem_rvalid_i && mem_rready_i) begin
            cnt_n       = cnt + 1;
            if(mem_rlast_i) begin
                wren_n  = 1'b1;
            end else begin
                wren_n  = 1'b0;
            end
        end else begin
            cnt_n       = 1'b0;
            wren_n      = 1'b0;
        end
        
    end
    assign wdata_data_o = data_buffer;
    assign wren_o       = wren;
    assign waddr_o      = waddr; 
    assign wdata_tag_o  = wdata_tag;
    assign miss_addr_fifo_rden_o = wren && (!miss_addr_fifo_empty_i);
endmodule