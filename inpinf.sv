/*Input Interface*/
`ifndef INPINF
 `define INPINF
 `include "primitives.vh"

module inpinf #(parameter XB = 10,
				parameter YB = 10,
				parameter PB = 8)
	(/*AUTOARG*/
	// Outputs
	px_in_ready, col_count, row_count, inc_mem_ptr, inf_data,
	// Inputs
	clk, rst, cfg_width, cfg_height, px_in_data, px_in_valid, inf_rd
	);

	//Globals
	input clk;
	input rst;

	//Frame Config
	input [XB-1:0] cfg_width;
	input [YB-1:0] cfg_height;
	
    // Interface data and control
	input [PB-1:0] px_in_data;
	input 		   px_in_valid;
	
	input 		   inf_rd;	    // Read from fifo
	output 		   px_in_ready; // Ready to accept data


	output [XB-1:0] col_count;	
	output [YB-1:0] row_count;
	output 			inc_mem_ptr;	
	output [PB-1:0] inf_data; // Data from fifo
	

	
	//Input fifo to collect pixels
	//Inputs to Fifo
	wire 		   inq_wr, inq_rd;
	wire [PB-1:0]  inq_datain;

	//Outputs
	wire 		   inq_full, inq_al_full;
	wire 		   inq_emty, inq_al_emty;
	wire [PB-1:0]  inq_dataout;
	
	hw_fifo inp_fifo (
					  // Outputs
					  .wr_full			(inq_full),
					  .wr_almost_full	(inq_al_full),
					  .rd_data			(inq_dataout),
					  .rd_empty			(inq_emty),
					  .rd_almost_empty	(inq_al_emty),
					  // Inputs
					  .clk				(clk),
					  .rst				(rst),
					  .wr_push			(inq_wr),
					  .wr_data			(inq_datain),
					  .rd_pop			(inq_rd));
	
	//Loading data into input fifo
	
	//Get data only if fifo is not full and frame is incomplete
	assign px_in_ready = ~inq_full && (row_count <= cfg_height);
	//Gate fifo write with valid for correct data
	assign inq_wr = px_in_valid & px_in_ready;
	assign inq_datain = px_in_data;

	//Reading data from fifo
	
	//Read from fifo if it is not empty and there is need to read
	assign inq_rd = ~inq_emty & inf_rd;
	assign inf_data = inq_dataout;		

	
	//Column Count - Counts number of pixels coming in
	reg [XB-1:0]   col_count;
	wire 		   inc_col_count;
	wire 		   rst_col_count;
	
	assign inc_col_count = inq_rd; //TODO: Check corner cases
	assign rst_col_count = (col_count == (cfg_width - 1'd1)) || rst;
	`EN_SYNC_RST_MSFF(col_count, col_count+1'b1, clk, inc_col_count, rst_col_count)

	//Row Count - Counts number of rows
	reg [YB-1:0]   row_count;
	wire 		   inc_row_count;
	wire 		   rst_row_count;
	reg 		   rst_row_count1F;

	assign inc_mem_ptr = rst_col_count;	
	assign inc_row_count = rst_col_count; // TODO: Check corner cases
	assign rst_row_count = (row_count == (cfg_height - 1'd1)) || rst;
	`EN_SYNC_RST_MSFF(row_count, row_count+1'b1, clk, inc_row_count, rst_row_count)


	
endmodule // inpInf
`endif


   
	
