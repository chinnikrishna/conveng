/*Rotating Counter*/
`ifndef ROTC
 `define ROTC

module rot_count(/*AUTOARG*/
	// Outputs
	cd,
	// Inputs
	base
	);
	input [1:0] base;
	output reg [1:0] cd [2:0];

	always_comb
	  begin
		  cd[0]='0;
		  cd[1]='0;
		  cd[2]='0;
		  cd[3]='0;		  
		  case(base)
			2'b00:
			  begin
				  cd[0]=2'd0;
				  cd[1]=2'd1;
				  cd[2]=2'd2;
			  end
			2'b01:
			  begin
				  cd[0]=2'd1;
				  cd[1]=2'd2;
				  cd[2]=2'd3;
			  end
			2'b10:
			  begin
				  cd[0]=2'd2;
				  cd[1]=2'd3;
				  cd[2]=2'd0;
			  end
			2'b11:
			  begin
				  cd[0]=2'd3;
				  cd[1]=2'd0;
				  cd[2]=2'd1;
			  end
		  endcase // case (base)
	  end
	
			
endmodule // rot_count
`endif


	
