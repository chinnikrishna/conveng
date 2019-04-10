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
	mem_used, mb_rd_addr, col_data,
	// Inputs
	clk, rst, cfg_width, cfg_height, mb_full, mb_minfill, pu_data
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

	// To memory unit
	output reg [NM-1:0] mem_used;
	output reg [XB-1:0] mb_rd_addr [NM-1:0];
	// To pixel unit
	output reg [PB-1:0] col_data [NM-1:0];
	


	//pu_col - Counts the column processed
	reg [XB-1:0]   pu_col;		
	reg 		   inc_pu_col; // when pu says done
	wire 		   rst_pu_col; // when rst or when cfg_width is met
	assign rst_pu_col = (pu_col == (cfg_width - 1'd1)) || rst;	
	`EN_SYNC_RST_MSFF(pu_col, pu_col+1'b1, clk, inc_pu_col, rst_pu_col)

	//pu_row - Counts the row processed
	reg [YB-1:0]   pu_row;	
	wire 		   inc_pu_row;
	wire 		   rst_pu_row;
	assign inc_pu_row = rst_pu_col;
	assign rst_pu_row = (pu_row == (cfg_height - 1'd1)) || rst;
	`EN_SYNC_RST_MSFF(pu_row, pu_row+1'b1, clk, inc_pu_row, rst_pu_row)

	//pass_cnt - Counts number of pixels passed to pixel unit
	reg [1:0]   pass_cnt;
	reg 		   inc_pass_cnt;
	wire 		   rst_pass_cnt;
	assign rst_pass_cnt = rst || (pass_cnt == 2'd3);
	`EN_SYNC_RST_MSFF(pass_cnt, pass_cnt+1'b1, clk, inc_pass_cnt, rst_pass_cnt)
   

	// Indicates if memory_unit has valid data to fuel pixel unit
	wire 		   mem_ready;
	assign mem_ready = mb_minfill[1];

	// Control FSM. 
	// TODO: 1. Need to make generic to support filters for different sizes
	// TODO: 2. Support parameters for multiple pixel units
	
	enum reg [10:0] {IDLE  = 11'b000_0000_0001,  // Idle
                     R1_FP = 11'b000_0000_0010,  // Row 1     - First Pixel
                     R1_OP = 11'b000_0000_0100,  // Row 1     - Other Pixels
                     R1_LP = 11'b000_0000_1000,  // Row 1     - Last Pixel
                     OR_FP = 11'b000_0001_0000,  // Other row - First Pixel
                     OR_OP = 11'b000_0010_0000,  // Other row - Other Pixels
                     OR_LP = 11'b000_0100_0000,  // Other row - Last Pixel
                     LR_FP = 11'b000_1000_0000,  // Last row  - First Pixel
                     LR_OP = 11'b001_0000_0000,  // Last row  - Other Pixels
                     LR_LP = 11'b010_0000_0000,  // Last row  - Last Pixel
					 DONE =  11'b100_0000_0000   // Send frame done here
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
		  inc_pass_cnt = 1'b0;
	
		  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
			begin
				mb_rd_addr[i] = '0;
				col_data[cntlr_i] = '0;
			end
		  

		  
		  case(cntlr_ps)
			IDLE:
			  begin
				  if(mem_ready)
					cntlr_ns = R1_FP;
				  else
					cntlr_ns = IDLE;
			  end
			R1_FP:
			  begin
				  if(pu_col == '0)
					begin
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  begin								
							  col_data[cntlr_i] = '0; //Send Data
							  mb_rd_addr[cntlr_i] = pu_col; //Issue memory read
						  end						  
						//Set State
						cntlr_ns = R1_FP;
						//Increment counters
						inc_pu_col = 1'b1;
					end
				  else
					cntlr_ns = R1_OP;				  								 
			  end
			R1_OP:
			  begin
				  if(pu_col <= (cfg_width-2'd2))
					 begin
						 //Send data
						 //TODO: parameterize a for loop here for filter window size
						 col_data[0] = pu_data[0];
						 col_data[1] = pu_data[1];
						 col_data[2] = pu_data[2];
						 col_data[3] = '0;
						 //Set State
						 cntlr_ns = R1_FP;
						 //Increment counter
						 inc_pu_col = 1'b1;
						 //Issue memory read
						 for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						   mb_rd_addr[cntlr_i] = pu_col;
					 end
				  else
					cntlr_ns = R1_LP;
			  end
			R1_LP:
			  begin
				  if(pu_col == (cfg_width-1'd1))
					 begin
						 //Send data
						 col_data[0] = pu_data[0];
						 col_data[1] = pu_data[1];
						 col_data[2] = '0;
						 col_data[3] = '0;
						 //Set State
						 cntlr_ns = R1_FP;
						 //Increment counter
						 inc_pu_col = 1'b1;
						 //Issue memory read
						 for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						   mb_rd_addr[cntlr_i] = pu_col;
					 end
				  else
					cntlr_ns = R1_LP;				  					
			
		  endcase // case (cntlr_ps)
	  end
	
							   
		  
	
	
	  
endmodule // cntl_unit
`endif
