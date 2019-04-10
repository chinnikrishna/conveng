/*Serial in parallel out shift register*/
`ifndef SIPO
 `define SIPO
 `include "primitives.vh"

module sipo # (parameter N  = 3,
			   parameter PB = 8)
	(/*AUTOARG*/
	// Outputs
	par_out, sipo_valid,
	// Inputs
	clk, rst, ser_in
	);
	localparam SHFT_SIZE = 2*PB*N;
	//Globals
	input clk;
	input rst;

	input [PB*2-1:0] ser_in;

	output reg [SHFT_SIZE-1:0] par_out;
	output 					   sipo_valid;
	
	reg [N-1:0] 			   pix_cnt;
	
	always_ff @(posedge clk)
	  begin
		  if(rst)
			begin
				pix_cnt = '0;
				par_out = '0;
			end
		  else
			begin
				if(pix_cnt != (N-1))
				   pix_cnt = pix_cnt+1'b1;
				par_out = {ser_in, par_out[SHFT_SIZE-(2*PB)-1:0]};
			end
	  end
	assign sipo_valid = (pix_cnt==N-1)?1'b1:1'b0;
	
endmodule // sipo
`endif



	
		  
