/*Pixel Unit*/
`ifndef PXLUNIT
 `define PXLUNIT
 `include "primitives.vh"
module pixel_unit # (parameter XB = 10,
					 parameter YB = 10,
					 parameter PB = 8,
					 parameter NM = 4)
	(/*AUTOARG*/
	// Outputs
	pix_out, proc_done,
	// Inputs
	clk, rst, col_data
	);

	//Globals
	input clk;
	input rst;

	// From control unit

	// From memory unit
	input [PB-1:0] col_data [NM-1:0];
	
	// To output interface
	output [PB*2-1:0] pix_out;
	output 			  proc_done;
	
	
	//Column processor
	wire [PB*2-1:0]		col_res;			

	col_proc cp (/*AUTOINST*/
				 // Outputs
				 .col_res				(col_res[PB*2-1:0]),
				 // Inputs
				 .clk					(clk),
				 .rst					(rst),
				 .col_data				(col_data/*[PB-1:0]*/));
	
	//Row Processor
	wire [PB*2-1:0] 	pix_out;
	
	row_proc rp(/*AUTOINST*/
				// Outputs
				.pix_out				(pix_out[PB*2-1:0]),
				// Inputs
				.clk					(clk),
				.rst					(rst),
				.col_res				(col_res[PB*2-1:0]));

endmodule // pixel_unit


module col_proc # (parameter PB  = 8,
				   parameter R1S = 0,
				   parameter R2S = 1,
				   parameter R3S = 0)
	(/*AUTOARG*/
	// Outputs
	col_res,
	// Inputs
	clk, rst, col_data
	);

	// Globals
	input clk;
	input rst;
	
	input [PB-1:0] col_data [3:0];

	// Output
	output reg [PB*2-1:0] col_res;

	wire [PB*2-1:0]   r1_shift, r2_shift, r3_shift;
	wire [PB*2-1:0]   col_sum;	
	reg  [PB*2-1:0]	  r1_shift_1F, r2_shift_1F, r3_shift_1F;

	// TODO: Parametrize this
	assign r1_shift = col_data[0] << R1S;
	assign r2_shift = col_data[1] << R2S;
	assign r3_shift = col_data[2] << R3S;

	`SYNC_RST_MSFF(r1_shift_1F, r1_shift, clk, rst)
	`SYNC_RST_MSFF(r2_shift_1F, r2_shift, clk, rst)
	`SYNC_RST_MSFF(r3_shift_1F, r3_shift, clk, rst)

	assign col_sum = r1_shift_1F + r2_shift_1F + r3_shift_1F;

	`SYNC_RST_MSFF(col_res, col_sum, clk, rst)

endmodule // col_proc

module row_proc # (parameter PB  = 8,
				   parameter C1S = 0,
				   parameter C2S = 1,
				   parameter C3S = 0)
	(/*AUTOARG*/
	// Outputs
	pix_out,
	// Inputs
	clk, rst, col_res
	);
	
	//Globals
	input clk;
	input rst;

	input [PB*2-1:0] col_res;

	output reg [PB*2-1:0] pix_out;


	wire [47:0] 	 par_out; //TODO: Parameterize 47
	wire 			 sipo_valid;	

	sipo sipo(.par_out(par_out),.sipo_valid(sipo_valid),.clk(clk),.rst(rst),.ser_in(col_res));

	wire [PB*2-1:0]  c1_shift, c2_shift, c3_shift;
	assign c1_shift = par_out[15:0]  << C1S;
	assign c2_shift = par_out[31:16] << C2S;
	assign c3_shift = par_out[47:32] << C3S;

	reg  [PB*2-1:0]	  c1_shift_1F, c2_shift_1F, c3_shift_1F;
	`EN_ASYNC_RST_MSFF(c1_shift_1F, c1_shift, clk, sipo_valid, rst)
	`EN_ASYNC_RST_MSFF(c2_shift_1F, c2_shift, clk, sipo_valid, rst)
	`EN_ASYNC_RST_MSFF(c3_shift_1F, c3_shift, clk, sipo_valid, rst)

	wire [PB*2-1:0]   row_sum;
	assign row_sum = c1_shift_1F + c2_shift_1F + c3_shift_1F;

	`SYNC_RST_MSFF(pix_out, row_sum, clk, rst)
	

endmodule // row_proc

`endif //  `ifndef PXLUNIT
