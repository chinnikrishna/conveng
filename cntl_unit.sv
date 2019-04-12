/*Control Unit*/
`ifndef CNTLR
 `define CNTLR
 `include "primitives.vh"
module cntl_unit # (parameter XB = 10,
					parameter YB = 10,
					parameter PB = 8,
					parameter NM = 4)
	(/*AUTOARG*/
	// Outputs
	mem_used, mb_rd_addr, col_data, en,
	// Inputs
	clk, rst, cfg_width, cfg_height, mb_full, mb_minfill, pu_data,
	out_inf_busy
	);

	//Globals
	input clk;
	input rst;

	//Frame Config
	input [XB-1:0] cfg_width;
	input [YB-1:0] cfg_height;
	
	// From memory unit
	input [NM-1:0] mb_full;
	input [NM-1:0] mb_minfill;

	// From memory unit
	input [PB-1:0] pu_data [NM-1:0];

	// From output interface
	input 		   out_inf_busy;
	

	// To memory unit
	output reg [NM-1:0] mem_used;
	output reg [XB-1:0] mb_rd_addr [NM-1:0];
	
	// To pixel unit
	output reg [PB-1:0] col_data [NM-1:0];
	output reg 			en;
	


	//pu_col - Counts the column processed
	reg [XB-1:0]   pu_col;		
	reg 		   inc_pu_col; // when pu says done
	wire 		   rst_pu_col; // when rst or when cfg_width is met
	assign rst_pu_col = (pu_col == cfg_width+1'd1) || rst;	
	`EN_SYNC_RST_MSFF(pu_col, pu_col+1'b1, clk, inc_pu_col, rst_pu_col)

	//pu_row - Counts the row processed
	reg [YB-1:0]   pu_row;	
	wire 		   inc_pu_row;
	wire 		   rst_pu_row;
	assign inc_pu_row = rst_pu_col;
	assign rst_pu_row = (pu_row == cfg_height) || rst;
	`EN_SYNC_RST_MSFF(pu_row, pu_row+1'b1, clk, inc_pu_row, rst_pu_row)
  
	reg [1:0] 	   base_cnt;
	reg 		   inc_base_cnt;	
	wire [1:0] 	   cd [2:0];
	wire 		   rst_base_cnt;
	assign rst_base_cnt = rst;	
	`EN_SYNC_RST_MSFF(base_cnt, base_cnt+1'b1, clk, inc_base_cnt, rst_base_cnt)
	rot_count rot_cnt(.base(base_cnt), .cd(cd));	
	
	
	// Indicates if memory_unit has valid data to fuel pixel unit
	wire 		   mem_ready;
	assign mem_ready = mb_minfill[1];

	// Indicates state machine is done
	reg 		   done;
	

	// Control FSM. 
	// TODO: 1. Need to make generic to support filters for different sizes
	// TODO: 2. Support parameters for multiple pixel units
	
	enum reg [3:0] {IDLE  = 4'b0001,  // Idle
					PP    = 4'b0010,
					WAIT  = 4'b0100,
    				DONE  = 4'b1000  // Send frame done here
					} cntlr_ps, cntlr_ns;
	// FSM sequential states
	`EN_RST_MSFFD(cntlr_ps, cntlr_ns, clk, 1'b1, IDLE, rst)

	integer 		cntlr_i;
	
	// FSM next state
	always_comb
	  begin
		  // Init
		  cntlr_ns = cntlr_ps;	  
		  mem_used = '0;
		  inc_pu_col = 1'b0;	  
		  inc_base_cnt = 1'b0;		  
		  en = 1'b0;
		  done = '0;
		  
		  
		  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
			begin
				mb_rd_addr[cntlr_i] = '0;
				col_data[cntlr_i] = '0;
			end	  
		  
		  case(cntlr_ps)
			IDLE:
			  begin
				  if(mem_ready)
					cntlr_ns = PP;
				  else
					cntlr_ns = IDLE;
			  end
			PP:
			  begin
				  // For all first columns
				  if(pu_col == '0) 
					begin
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  begin
							  col_data[cd[cntlr_i]] = '0;
							  mb_rd_addr[cd[cntlr_i]] = pu_col;
						  end
					end
				  // For first row other columns
				  else if ((pu_col > 0) && (pu_row == 0) && (pu_col < cfg_width+1'd1))
					begin
						col_data[0] = '0; // Send zeros in out of boundary
						col_data[1] = pu_data[0];// Send memory data
						col_data[2] = pu_data[1];
						col_data[3] = '0;
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cntlr_i] = pu_col; // Issue memory read
					end
				  // For first row last pixel
				  else if((pu_col > 0) && (pu_col == (cfg_width+1'd1)) 
						  && (pu_row == 0)) //Last pixel data
					begin
						//Send data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;
					end

				  // Other pixels
				  else if((pu_row > 0) && (pu_col > 0) 
						  && (pu_col < (cfg_width+1'd1))) //Other pixels
					for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
					  begin
						  col_data[cd[cntlr_i]] = pu_data[cd[cntlr_i]];
						  mb_rd_addr[cd[cntlr_i]] = pu_col;
					  end
				  // Other pixels last data
				  else if((pu_row > 0) && (pu_col > 0) && (pu_col == (cfg_width+1'd1)))
					for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
					  col_data[cd[cntlr_i]] = pu_data[cd[cntlr_i]];

				  //Last Row other columns
				  else if ((pu_col > 0) && (pu_row == cfg_height) && (pu_col < cfg_width+1'd1))
					begin
						col_data[cd[0]] = pu_data[cd[0]];
						col_data[cd[1]] = pu_data[cd[1]];
						col_data[cd[2]] = '0;
						col_data[cd[3]] = '0;
						
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cd[cntlr_i]] = pu_col; // Issue memory read
					end
				  //Last row last column
				  else if((pu_row == cfg_height) && (pu_col > 0) && (pu_col == (cfg_width+1'd1)))
					begin
						col_data[cd[0]] = pu_data[cd[0]];
						col_data[cd[1]] = pu_data[cd[1]];
						col_data[cd[2]] = '0;
						col_data[cd[3]] = '0;
					end
				  else
					begin
						inc_pu_col = 1'b0;
						en = 1'b0;
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  col_data[cntlr_i] = '0;
					end
				  
				  // State management
				  if (out_inf_busy)// || (pu_col == (cfg_width+1'd1)))
					begin
						cntlr_ns = WAIT;
						en = 1'b1;						
					end
				  else if(done)
					begin
						cntlr_ns = DONE;
					end
				  else
					begin
						// Increment counter and enable processor
						inc_pu_col = 1'b1;
						// Enable processors
						en=1'b1;						
				  		// Set State
						cntlr_ns = PP;
					end				  
				
			  end // case: PP
			WAIT:
			  begin
				  if(~out_inf_busy)
					cntlr_ns = PP;
				  else
					cntlr_ns = WAIT;
			  end
			DONE:
			  begin
				  cntlr_ns = IDLE;
			  end
			
			

			
				  		
				  
			
		  endcase // case (cntlr_ps)
	  end
	
							   
		  
	
	
	  
endmodule // cntl_unit
`endif
