`ifndef OUTINF
 `define OUTINF
 `include "primitives.vh"
module outinf # (parameter XB = 10,
				 parameter YB = 10,
				 parameter PB = 8)
	(/*AUTOARG*/
	// Outputs
	px_out_data, px_out_valid, px_out_last_x, px_out_last_y, done,
	out_inf_busy,
	// Inputs
	clk, rst, cfg_width, cfg_height, pix_data, pix_en, px_out_ready
	);

	// Globals
	input clk;
	input rst;

	// Frame Config
	input [XB-1:0] cfg_width;
	input [YB-1:0] cfg_height;
	
	input [PB-1:0] pix_data;
	input 		   pix_en;
	
	input 		   px_out_ready;
	
	output [PB-1:0] px_out_data;
	output 			px_out_valid;
	output 			px_out_last_x;
	output 			px_out_last_y;
	output 			done;
	output 			out_inf_busy;
	

	wire				rd_almost_empty, rd_empty;		
	wire [PB-1:0]		rd_data, wr_data;
	wire				wr_almost_full, wr_full;			
	wire				wr_push, rd_pop;				

	hw_fifo out_fifo (
					  // Outputs
					  .wr_full			(wr_full),
					  .wr_almost_full	(wr_almost_full),
					  .rd_data			(rd_data[PB-1:0]),
					  .rd_empty			(rd_empty),
					  .rd_almost_empty	(rd_almost_empty),
					  // Inputs
					  .clk				(clk),
					  .rst				(rst),
					  .wr_push			(wr_push),
					  .wr_data			(wr_data[PB-1:0]),
					  .rd_pop			(rd_pop));


	// Reading from fifo to interface
	assign px_out_data = rd_data;
	assign rd_pop = px_out_ready && ~rd_empty;
	assign px_out_valid = rd_pop;	
					

	// Writing data to fifo
	assign wr_data = pix_data;
	assign wr_push = pix_en & ~wr_full;

/*	reg [XB-1:0] 		wr_cnt;
	wire 				rst_wr_cnt;
	assign rst_wr_cnt = (wr_cnt == cfg_width)
	`EN_SYNC_RST_MSFF(wr_cnt, wr_cnt + 1'b1, clk, wr_push, rst_out_col)*/
	// Output counters
	// out_col - Counts number of pixels written to output interface
	reg [XB-1:0] 		out_col;
	wire 				rst_out_col;
	assign rst_out_col = (out_col == cfg_width) || rst;
	
	`EN_SYNC_RST_MSFF(out_col, out_col + 1'b1, clk, rd_pop, rst_out_col)

	// out_row - Counts number of rows written to output interface
	reg [XB-1:0] 		out_row;
	wire 				rst_out_row;
	assign rst_out_row = (out_row == cfg_height) || rst;
	
	`EN_SYNC_RST_MSFF(out_row, out_row + 1'b1, clk, rst_out_col, rst_out_row)
	
	// Status signals
	assign out_inf_busy = wr_full?1'b1:1'b0;
	assign px_out_last_x = rst_out_col?1'b1:1'b0;
	assign px_out_last_y = rst_out_row?1'b1:1'b0;

	assign done = (rst_out_col && rst_out_row)?1'b1:1'b0;
	
	
	
	
endmodule // outinf
`endif
