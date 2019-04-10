/*Rotating Counter*/
`ifndef ROTC
 `define ROTC

module rot_count(/*AUTOARG*/
	// Outputs
	cd0, cd1, cd2,
	// Inputs
	base
	);
	input [1:0] base;
	output reg [1:0] cd0;
	output reg [1:0] cd1;
	output reg [1:0] cd2;

	always_comb
	  begin
		  cd0='0;
		  cd1='0;
		  cd2='0;		  
		  case(base)
			2'b00:
			  begin
				  cd0=2'd0;
				  cd1=2'd1;
				  cd2=2'd2;
			  end
			2'b01:
			  begin
				  cd0=2'd1;
				  cd1=2'd2;
				  cd2=2'd3;
			  end
			2'b10:
			  begin
				  cd0=2'd2;
				  cd1=2'd3;
				  cd2=2'd0;
			  end
			2'b11:
			  begin
				  cd0=2'd3;
				  cd1=2'd0;
				  cd2=2'd1;
			  end
		  endcase // case (base)
	  end
	
			
endmodule // rot_count
`endif


	
