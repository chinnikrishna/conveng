`ifndef TOP
 `define TOP
 `include "primitives.vh"
module top #(
			 parameter XB = 10,
			 parameter YB = 10,
			 parameter PB = 8)
	(/*AUTOARG*/
	// Outputs
	px_in_ready, px_out_data, px_out_last_x, px_out_last_y,
	px_out_valid, done,
	// Inputs
	clk, rst, cfg_width, cfg_height, px_in_data, px_in_valid,
	px_out_ready
	);

	//Globals
	input clk;
	input rst;

	//Frame config
	input [XB-1:0] cfg_width;
	input [YB-1:0] cfg_height;

	//Input Interface Data
	input [PB-1:0] px_in_data;

	//Input Interface Status
	input 		   px_in_valid;	
	output 		   px_in_ready;

	//Output Interface Data
	output [PB-1:0] px_out_data;

	//Output Interface Status
	input  			px_out_ready;
	output 			px_out_last_x;
	output 	  		px_out_last_y;
	output 			px_out_valid;
    output 			done;
	

	wire [XB-1:0] 	col_count;
	wire [YB-1:0] 	row_count;
	
	//Input Interface
	inpinf inpinf(/*AUTOINST*/
				  // Outputs
				  .px_in_ready			(px_in_ready),
				  .col_count			(col_count[XB-1:0]),
				  .row_count			(row_count[YB-1:0]),
				  // Inputs
				  .clk					(clk),
				  .rst					(rst),
				  .cfg_width			(cfg_width[XB-1:0]),
				  .cfg_height			(cfg_height[YB-1:0]),
				  .px_in_data			(px_in_data[PB-1:0]),
				  .px_in_valid			(px_in_valid));
	

	
			   
	
endmodule // top
`endif //  `ifndef TOP
  
		  
