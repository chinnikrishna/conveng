/*Memory Unit*/
`ifndef MEMUNIT
 `define MEMUNIT
 `include "primitives.vh"
module mem_unit #(parameter XB = 10,
				  parameter YB = 10,
				  parameter PB = 8)
	(/*AUTOARG*/
	// Outputs
	inf_rd, mem_bank_full, mem_bank_minfill, pix_data,
	// Inputs
	clk, rst, col_count, row_count, cfg_width, cfg_height, inf_data,
	inc_mem_ptr, mem_used, mb_rd_addr
	);

	//Globals
	input clk;
	input rst;

	//Pixel Counts
	input [XB-1:0] col_count;      //Present col of data sent in row  
	input [YB-1:0] row_count;      //Present row of data sent in
	input [XB-1:0] cfg_width;	
	input [YB-1:0] cfg_height;

	input [PB-1:0] inf_data;       //Data from interface fifo
	input 		   inc_mem_ptr;    //Increment memory pointer

	input [3:0]    mem_used;       //1-used 0-not used
	
	output reg 	   inf_rd;         //Read from interface fifo
	output [3:0]   mem_bank_full;
	output [3:0]   mem_bank_minfill;
	
	// Read interface
	input [XB-1:0] mb_rd_addr [3:0];
	output [PB-1:0] pix_data [3:0]; // Data from 4 memory banks
	
	
	
	// Counts the memory bank being written
	reg [1:0] 	   mem_count;
	`EN_ASYNC_RST_MSFF(mem_count, mem_count+1'b1, clk, inc_mem_ptr, rst)

	
	// Mem Data
	reg [PB-1:0]  mem_wr_data [3:0];
	// Mem Addr
	reg [XB-1:0]  mem_wr_addr [3:0];
	// Mem en
	reg [3:0] 	   mem_wr_en;

	reg  [3:0] 	   mem_bank_busy;    //Indicates if mem bank is free or being used 1-busy 0-free
	wire [3:0] 	   mem_bank_full;    //Indicates if mem bank is fully filled
	wire [3:0] 	   togle_stat;       //Toggles memory bank status	
	wire [3:0] 	   mem_bank_minfill; //Indicates if mem bank is filled minimum

	genvar 		   mem_i;
	generate
		for(mem_i=0; mem_i<4; mem_i=mem_i+1)
		  begin
			  mem_gen mem (.rd_data			(pix_data[mem_i]),
						   .clk				(clk),
						   .rd_addr			(mb_rd_addr[mem_i]),
						   .wr_addr			(mem_wr_addr[mem_i]),
						   .wr_en		    (mem_wr_en[mem_i]),
						   .wr_data			(mem_wr_data[mem_i]));
			  //Mem bank is full if col_count = cfg_width
			  assign mem_bank_full[mem_i] = (mem_count == mem_i) &&
											(col_count == (cfg_width-1'd1));
			  //Toggle busy when it is full and after it is used. default is zero.
			  assign togle_stat[mem_i] = mem_bank_full[mem_i] || mem_used[mem_i];
			  
	`EN_ASYNC_RST_MSFF(mem_bank_busy[mem_i], ~mem_bank_busy[mem_i], clk, togle_stat[mem_i], rst)
		  end	
	endgenerate


	// Demux for toggling input fifo read
	always_comb
	  begin
		  inf_rd = '0;
		  case(mem_count)
			2'b00:
			  inf_rd = (row_count <= cfg_height) && ~mem_bank_busy[0];
			2'b01:
			  inf_rd = (row_count <= cfg_height) && ~mem_bank_busy[1];
			2'b10:
			  inf_rd = (row_count <= cfg_height) && ~mem_bank_busy[2];
			2'b11:
			  inf_rd = (row_count <= cfg_height) && ~mem_bank_busy[3];
		  endcase 
	  end

	// Demux for writing the data into memory banks
	always_comb
	  begin
		  mem_wr_data[0] = '0;mem_wr_data[1] = '0;mem_wr_data[2] = '0;mem_wr_data[3] = '0;
		  mem_wr_addr[0] = '0;mem_wr_addr[1] = '0;mem_wr_addr[2] = '0;mem_wr_addr[3] = '0;
		  mem_wr_en = '0;
		  
		  case(mem_count)
			2'b00:
			  begin
				  mem_wr_data[0] = inf_data;
				  mem_wr_addr[0] = col_count;
				  mem_wr_en[0] = inf_rd;
			  end
			2'b01:
			  begin
				  mem_wr_data[1] = inf_data;
				  mem_wr_addr[1] = col_count;
				  mem_wr_en[1] = inf_rd;
			  end
			2'b10:
			  begin
				  mem_wr_data[2] = inf_data;
				  mem_wr_addr[2] = col_count;
				  mem_wr_en[2] = inf_rd;
			  end
			2'b11:
			  begin
				  mem_wr_data[3] = inf_data;
				  mem_wr_addr[3] = col_count;
				  mem_wr_en[3] = inf_rd;
			  end
		  endcase // case (mem_count)
	  end
	

	
	
	
	

	
endmodule // mem_unit
`endif

