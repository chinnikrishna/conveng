/*Memory Unit*/
`ifndef MEMUNIT
 `define MEMUNIT
 `include "primitives.vh"
module mem_unit #(parameter XB = 10,
				  parameter YB = 10,
				  parameter PB = 8,
				  parameter NM = 4)
	(/*AUTOARG*/
	// Outputs
	inf_rd, mb_full, mb_minfill, mem_data,
	// Inputs
	clk, rst, cfg_width, cfg_height, col_count, row_count, inf_data,
	inc_mem_ptr, mem_used, mb_rd_addr
	);

	localparam MINFILL_WID = 3;
	
	//Globals
	input clk;
	input rst;

	//Frame Config
	input [XB-1:0] cfg_width;	
	input [YB-1:0] cfg_height;
	
	//From input interface
	input [XB-1:0] col_count;      //Present col of data sent in row  
	input [YB-1:0] row_count;      //Present row of data sent in	
	input [PB-1:0] inf_data;       //Data from interface fifo
	input 		   inc_mem_ptr;    //Increment memory pointer

	//From Control unit
	input [NM-1:0]    mem_used;       //1-used 0-not used
	input [XB-1:0] mb_rd_addr [NM-1:0];

	//To input interface
	output reg 	   inf_rd;         //Read from interface fifo
	output [NM-1:0]   mb_full;
	output [NM-1:0]   mb_minfill;
	
	//To control unit
	output [PB-1:0] mem_data [NM-1:0]; // Data from 4 memory banks
	
	
	
	// Counts the memory bank being written
	reg [1:0] 	   mem_count;
	`EN_ASYNC_RST_MSFF(mem_count, mem_count+1'b1, clk, inc_mem_ptr, rst)

	
	// Mem Data
	reg [PB-1:0]  mem_wr_data [NM-1:0];
	// Mem Addr
	reg [XB-1:0]  mem_wr_addr [NM-1:0];
	// Mem en
	reg [NM-1:0] 	   mem_wr_en;

	reg  [NM-1:0] 	   mb_busy;    //Indicates if mem bank is free or being used 1-busy 0-free
	wire [NM-1:0] 	   mb_full;    //Indicates if mem bank is fully filled
	wire [NM-1:0] 	   tog_mb_busy; //Toggles memory bank status
	
	reg [NM-1:0] 	   mb_minfill;//Indicates if min width of membak is filled
	wire [NM-1:0] 	   en_mb_minfill;
	
		
	genvar 		   mem_i;
	generate
		// Instantiating memories
		for(mem_i=0; mem_i<NM; mem_i=mem_i+1)
		  begin
			  mem_gen mem (.rd_data			(mem_data[mem_i]),
						   .clk				(clk),
						   .rd_addr			(mb_rd_addr[mem_i]),
						   .wr_addr			(mem_wr_addr[mem_i]),
						   .wr_en		    (mem_wr_en[mem_i]),
						   .wr_data			(mem_wr_data[mem_i]));
		  end	
		
		// Setting full, busy and minfill signals
		for(mem_i=0; mem_i<NM; mem_i=mem_i+1)
		  begin
			  //Mem bank is full if col_count = cfg_width
			  assign mb_full[mem_i] = (mem_count == mem_i) &&
											(col_count == (cfg_width-1'd1));
			  //Toggle busy when it is full and after it is used. default is zero.
			  assign tog_mb_busy[mem_i] = mb_full[mem_i] || mem_used[mem_i];

			  //Toggle flip-flop - Busy status
			  `EN_ASYNC_RST_MSFF(mb_busy[mem_i], ~mb_busy[mem_i], clk, tog_mb_busy[mem_i], rst)
			  
			  //Set-Reset flip-flop - min fill status
			  assign en_mb_minfill[mem_i] = (mem_count == mem_i) && (col_count >= MINFILL_WID);			  
			  `EN_SYNC_RST_MSFF(mb_minfill[mem_i], 1'b1, clk, en_mb_minfill[mem_i], (rst || mem_used[mem_i]))	
		  end	
 	endgenerate

	// TODO: Move this logic into generate for better scalability
	// Demux for toggling input fifo read
	always_comb
	  begin
		  inf_rd = '0;
		  case(mem_count)
			2'b00:
			  inf_rd = (row_count <= cfg_height) && ~mb_busy[0];
			2'b01:
			  inf_rd = (row_count <= cfg_height) && ~mb_busy[1];
			2'b10:
			  inf_rd = (row_count <= cfg_height) && ~mb_busy[2];
			2'b11:
			  inf_rd = (row_count <= cfg_height) && ~mb_busy[3];
		  endcase 
	  end

	// TODO: Move this logic into generate for better scalability
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

