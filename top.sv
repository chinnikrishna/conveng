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
	input wire clk;
	input wire rst;

	//Frame config
	input wire [XB-1:0] cfg_width;
	input wire [YB-1:0] cfg_height;

	//Input Interface Data
	input wire [PB-1:0] px_in_data;

	//Input Interface Status
	input wire 			px_in_valid;	
	output reg 			px_in_ready;

	//Output Interface Data
	output reg [PB-1:0] px_out_data;

	//Output Interface Status
	output reg 			px_out_last_x;
	output reg 			px_out_last_y;
	output reg 			px_out_valid;
    output reg 			done;
	
	input wire 			px_out_ready;
			   
	/*AUTOINPUT*/
	/*AUTOOUTPUT*/
	/*AUTOREG*/

	// Have an interface module
	reg [7:0] 			pixMem [7:0];
	reg [3:0] 			pixCount;
	reg [9:0] 			rowCount;
	
	enum reg [1:0] 		{IDLE=2'b00, RDY=2'b01, WAIT=2'b10, DATA=2'b11} rcv_ps, rcv_ns;
	`EN_RST_MSFFD(rcv_ps, rcv_ns, clk, 1'b1, IDLE, rst)

	always_comb
	  begin
		  case(rcv_ps)
			IDLE:
			  if(px_in_valid)
				begin
					rcv_ns=RDY;					
				end
			  else
				begin
					rcv_ns = IDLE;
					px_in_ready=1'b0;
				end										
			RDY:
			  begin
				  px_in_ready = 1'b1;
				  rcv_ns = WAIT;
			  end		
		    WAIT:
			  begin
				  px_in_ready=1'b1;
				  rcv_ns=DATA;
			  end				 
			DATA:
			  begin
				  pixMem[0][0]=px_in_data;
				  if(px_in_valid)
					rcv_ns=RDY;
				  else
					rcv_ns=IDLE;
			  end
		  endcase // case (rcv_ps)
	  end 						  						 		 	
	// Have a pixel module
	
endmodule // top
	
  
		  
