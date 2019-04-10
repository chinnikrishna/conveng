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
	pix_out, proc_done, valid,
	// Inputs
	clk, rst, en, col_data
	);

	//Globals
	input clk;
	input rst;

	input en;
	
	// From control unit

	// From memory unit
	input [PB-1:0] col_data [NM-1:0];
	
	// To output interface
	output [PB*2-1:0] pix_out;
	output 			  proc_done;
	output 			  valid;
	
	
	//Column processor
	wire [PB*2-1:0]		col_res;
	wire 				cp_en;	
	wire 				cp_valid;
	
	col_proc cp (/*AUTOINST*/
				 // Outputs
				 .col_res				(col_res[PB*2-1:0]),
				 .cp_valid				(cp_valid),
				 // Inputs
				 .clk					(clk),
				 .rst					(rst),
				 .cp_en					(cp_en),
				 .col_data				(col_data/*[PB-1:0]*/));
	
	//Row Processor
	wire [PB*2-1:0] 	pix_out;
	wire 				rp_en;
	wire 				rp_valid;
	
	row_proc rp(/*AUTOINST*/
				// Outputs
				.pix_out				(pix_out[PB*2-1:0]),
				.rp_valid				(rp_valid),
				// Inputs
				.clk					(clk),
				.rst					(rst),
				.rp_en					(rp_en),
				.col_res				(col_res[PB*2-1:0]));

	assign cp_en = en;
	assign rp_en = cp_valid;
	assign valid = rp_valid;	
	
endmodule // pixel_unit


module col_proc # (parameter PB  = 8,
				   parameter R1S = 0,
				   parameter R2S = 1,
				   parameter R3S = 0)
	(/*AUTOARG*/
	// Outputs
	col_res, cp_valid,
	// Inputs
	clk, rst, cp_en, col_data
	);

	// Globals
	input clk;
	input rst;
	input cp_en;
	
	input [PB-1:0] col_data [3:0];

	// Output
	output reg [PB*2-1:0] col_res;
	output 				  cp_valid;
	
	wire [PB*2-1:0]   r1_shift, r2_shift, r3_shift;
	wire [PB*2-1:0]   col_sum;	
	reg  [PB*2-1:0]	  r1_shift_1F, r2_shift_1F, r3_shift_1F;
	
	reg 			  en1F, en2F;
	`SYNC_RST_MSFF(en1F, cp_en, clk, rst)
	`SYNC_RST_MSFF(en2F, en1F, clk, rst)
	assign cp_valid = en2F;
	
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
	pix_out, rp_valid,
	// Inputs
	clk, rst, rp_en, col_res
	);
	
	//Globals
	input clk;
	input rst;

	input rp_en;	
	input [PB*2-1:0] col_res;

	output reg [PB*2-1:0] pix_out;
	output 				  rp_valid;
	


	wire [47:0] 	 par_out; //TODO: Parameterize 47
	wire 			 sipo_valid;	

	sipo sipo(.par_out(par_out),.sipo_valid(sipo_valid),
			  .clk(clk),.rst(rst),.ser_in(col_res),.en(rp_en));

	wire [PB*2-1:0]  c1_shift, c2_shift, c3_shift;
	wire [PB*2-1:0]  c1, c2, c3;
	assign c1 = par_out[15:0];
	assign c2 = par_out[31:16];
	assign c3 = par_out[47:32];
	
	assign c1_shift = c1 << C1S;
	assign c2_shift = c2 << C2S;
	assign c3_shift = c3 << C3S;

	reg  [PB*2-1:0]	  c1_shift_1F, c2_shift_1F, c3_shift_1F;
	`EN_ASYNC_RST_MSFF(c1_shift_1F, c1_shift, clk, sipo_valid, rst)
	`EN_ASYNC_RST_MSFF(c2_shift_1F, c2_shift, clk, sipo_valid, rst)
	`EN_ASYNC_RST_MSFF(c3_shift_1F, c3_shift, clk, sipo_valid, rst)

	wire [PB*2-1:0]   row_sum;
	assign row_sum = c1_shift_1F + c2_shift_1F + c3_shift_1F;

	`SYNC_RST_MSFF(pix_out, row_sum, clk, rst)

	//Flopping 3 times to account for SIPO delay 
	reg 			  en1F, en2F, en3F;
	`SYNC_RST_MSFF(en1F, sipo_valid, clk, rst)
	`SYNC_RST_MSFF(en2F, en1F, clk, rst)
	`SYNC_RST_MSFF(en3F, en2F, clk, rst)
	assign rp_valid = en3F;


endmodule // row_proc

`endif //  `ifndef PXLUNIT
