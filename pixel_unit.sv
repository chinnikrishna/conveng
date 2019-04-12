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
	pix_out, proc_done, pix_valid,
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
	output [PB-1:0] pix_out;
	output 			proc_done;
	output 			pix_valid;
	
	
	//Column processor
	wire [PB*2-1:0] col_res;
	wire 			cp_en;	
	wire 			cp_valid;
	
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
	wire [PB-1:0] 	pix_out;
	wire 			rp_en;
	wire 			rp_valid;
	
	row_proc rp(/*AUTOINST*/
				// Outputs
				.pix_out				(pix_out[PB-1:0]),
				.rp_valid				(rp_valid),
				// Inputs
				.clk					(clk),
				.rst					(rst),
				.rp_en					(rp_en),
				.col_res				(col_res[PB*2-1:0]));

	assign cp_en = en;
	assign rp_en = cp_valid;
	assign pix_valid = rp_valid;	
	
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
	assign cp_valid = en2F & cp_en;
	
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
				   parameter C1S = 0, // Column1 shift
				   parameter C2S = 1, // Column2 shift
				   parameter C3S = 0, // Column3 shift
				   parameter DIV = 4) // Divider shift
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

	output reg [PB-1:0] pix_out;
	output 				rp_valid;
	

	// Serial-in Parallel-Out shift register. 16x3 width
	reg [(PB*2*3)-1:0] 	par_out;
	`EN_SYNC_RST_MSFF(par_out, {col_res, par_out[(PB*6)-1:(PB*2)]}, clk, rp_en, rst)

	// Delay rp_en by 3 cycles to account for shift register
	reg [2:0] 				 rp_enF;
	`SYNC_RST_MSFF(rp_enF[0], rp_en, clk, rst)
	`SYNC_RST_MSFF(rp_enF[1], rp_enF[0], clk, rst)
	`SYNC_RST_MSFF(rp_enF[2], rp_enF[1], clk, rst)

	// Shift to do kernel multiplication
	wire [PB*2-1:0]  c1_shift, c2_shift, c3_shift;	
	assign c1_shift = par_out[(PB*2)-1:0] << C1S;
	assign c2_shift = par_out[(PB*4)-1:PB*2] << C2S;
	assign c3_shift = par_out[(PB*6)-1:PB*4] << C3S;

	reg  [PB*2-1:0]	  c1_shift_1F, c2_shift_1F, c3_shift_1F;
	`EN_ASYNC_RST_MSFF(c1_shift_1F, c1_shift, clk, rp_enF[2], rst)
	`EN_ASYNC_RST_MSFF(c2_shift_1F, c2_shift, clk, rp_enF[2], rst)
	`EN_ASYNC_RST_MSFF(c3_shift_1F, c3_shift, clk, rp_enF[2], rst)

	wire [PB*2-1:0]   row_sum;
	reg [PB*2-1:0] 	  sum_unshftd;
	
	assign row_sum = c1_shift_1F + c2_shift_1F + c3_shift_1F + 4'd8;
	`SYNC_RST_MSFF(sum_unshftd, row_sum, clk, rst)

	wire [PB*2-1:0]   sum_shftd;
	assign sum_shftd = sum_unshftd >> DIV;	
	`SYNC_RST_MSFF(pix_out, sum_shftd[PB-1:0], clk, rst)

	//Flopping 3 times to account for pipeline delay 
	reg 			  en1F, en2F, en3F, en4F;
	`SYNC_RST_MSFF(en1F, rp_enF[2], clk, rst)
	`SYNC_RST_MSFF(en2F, en1F, clk, rst)
	`SYNC_RST_MSFF(en3F, en2F, clk, rst)

	assign rp_valid = en3F;


endmodule // row_proc

`endif //  `ifndef PXLUNIT
