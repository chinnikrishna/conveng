/* Simple Generic Memory*/
`ifndef MEMGEN
 `define MEMGEN

module mem_gen #(ADDRW=10,
				 DATAW=8)
	(/*AUTOARG*/
	// Outputs
	rd_data,
	// Inputs
	clk, rd_addr, wr_addr, wr_en, wr_data
	);

	// Globals
	input clk;
	
	// Read Port
	input [ADDRW-1:0] rd_addr;
	output [DATAW-1:0] rd_data;
	
	
	// Write Port
	input [ADDRW-1:0] wr_addr;
	input 			  wr_en;
	input [DATAW-1:0] wr_data;
	
	// Memory
	reg [DATAW-1:0]   ram [(2**ADDRW)-1:0];

	
	always @(posedge clk)
	  begin
		  if(wr_en)
			ram[wr_addr] <= wr_data;
	  end

	assign rd_data = ram[rd_addr];
	
	
endmodule // mem_gen
`endif
