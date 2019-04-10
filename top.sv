`ifndef TOP
 `define TOP
 `include "primitives.vh"
module top #(
			 parameter XB = 10,
			 parameter YB = 10,
			 parameter PB = 8,
			 parameter NM = 4)
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
	

	//Input Interface
	wire 			inc_mem_ptr;
	wire [XB-1:0] 	col_count;
	wire [YB-1:0] 	row_count;
	wire [PB-1:0] 	inf_data;	
	wire 			inf_rd;
	

	inpinf inpinf(/*AUTOINST*/
				  // Outputs
				  .px_in_ready			(px_in_ready),
				  .col_count			(col_count[XB-1:0]),
				  .row_count			(row_count[YB-1:0]),
				  .inc_mem_ptr			(inc_mem_ptr),
				  .inf_data				(inf_data[PB-1:0]),
				  // Inputs
				  .clk					(clk),
				  .rst					(rst),
				  .cfg_width			(cfg_width[XB-1:0]),
				  .cfg_height			(cfg_height[YB-1:0]),
				  .px_in_data			(px_in_data[PB-1:0]),
				  .px_in_valid			(px_in_valid),
				  .inf_rd				(inf_rd));
	
	// Memory Unit
	wire [NM-1:0] 		mem_used;
	wire [NM-1:0] 		mb_full;
	wire [NM-1:0] 		mb_minfill;
	wire [PB-1:0] 		mem_data [NM-1:0];
	wire [XB-1:0] 		mb_rd_addr [NM-1:0];
	
			  	  							
	mem_unit memunit(/*AUTOINST*/
					 // Outputs
					 .inf_rd			(inf_rd),
					 .mb_full			(mb_full[NM-1:0]),
					 .mb_minfill		(mb_minfill[NM-1:0]),
					 .mem_data			(mem_data/*[PB-1:0]*/),
					 // Inputs
					 .clk				(clk),
					 .rst				(rst),
					 .cfg_width			(cfg_width[XB-1:0]),
					 .cfg_height		(cfg_height[YB-1:0]),
					 .col_count			(col_count[XB-1:0]),
					 .row_count			(row_count[YB-1:0]),
					 .inf_data			(inf_data[PB-1:0]),
					 .inc_mem_ptr		(inc_mem_ptr),
					 .mem_used			(mem_used[NM-1:0]),
					 .mb_rd_addr		(mb_rd_addr/*[XB-1:0]*/));
	

	// Control Unit
	wire [PB-1:0] 		pu_data [NM-1:0];
	wire [PB-1:0] 		col_data [NM-1:0];
	wire 				en;
	
	assign pu_data = mem_data;
	
	cntl_unit cntlr(/*AUTOINST*/
					// Outputs
					.mem_used			(mem_used[NM-1:0]),
					.mb_rd_addr			(mb_rd_addr/*[XB-1:0]*/),
					.col_data			(col_data/*[PB-1:0]*/),
					.en					(en),
					// Inputs
					.clk				(clk),
					.rst				(rst),
					.cfg_width			(cfg_width[XB-1:0]),
					.cfg_height			(cfg_height[YB-1:0]),
					.mb_full			(mb_full[NM-1:0]),
					.mb_minfill			(mb_minfill[NM-1:0]),
					.pu_data			(pu_data/*[PB-1:0]*/));
	
	wire [PB*2-1:0] 	pix_out;
	wire 				proc_done;

	pixel_unit pixunit(/*AUTOINST*/
					   // Outputs
					   .pix_out			(pix_out[PB*2-1:0]),
					   .proc_done		(proc_done),
					   .valid			(valid),
					   // Inputs
					   .clk				(clk),
					   .rst				(rst),
					   .en				(en),
					   .col_data		(col_data/*[PB-1:0]*/));
	


	assign px_out_data = pix_out[7:0];
	assign px_out_valid = valid;
	assign px_out_last_x = '0;
	assign px_out_last_y = '0;
	
/*	initial
	  begin
		  #0 mem_used = '0;		  
		  #1200 mem_used[0] = 1'b1;
		  #10 mem_used[0] = 1'b0;
		  #50 mb_rd_addr[0] = 1;mb_rd_addr[1] = 1;mb_rd_addr[2] = 1;mb_rd_addr[3] = 1;
		  
	  end
*/	
			   
	
endmodule // top
`endif //  `ifndef TOP
  
		  
