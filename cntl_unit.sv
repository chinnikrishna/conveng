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
	output reg 			en;
	


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
   
	reg [1:0] 	   base_cnt;
	reg 		   inc_base_cnt;	
	wire [1:0] 	   cd0, cd1, cd2;
	wire 		   rst_base_cnt;
	assign rst_base_cnt = rst;	
	`EN_SYNC_RST_MSFF(base_cnt, base_cnt+1'b1, clk, inc_base_cnt, rst_base_cnt)
	rot_count rot_cnt(.base(base_cnt), .cd0(cd0), .cd1(cd1), .cd2(cd2));
	
	
	// Indicates if memory_unit has valid data to fuel pixel unit
	wire 		   mem_ready;
	assign mem_ready = mb_minfill[1];

	// Control FSM. 
	// TODO: 1. Need to make generic to support filters for different sizes
	// TODO: 2. Support parameters for multiple pixel units
	
	enum reg [13:0] {IDLE  = 14'b00_0000_0000_0001,  // Idle
                     R1_FP = 14'b00_0000_0000_0010,  // Row 1     - First Pixel
                     R1_OP = 14'b00_0000_0000_0100,  // Row 1     - Other Pixels
                     R1_LP = 14'b00_0000_0000_1000,  // Row 1     - Last Pixel
					 R1_Z0 = 14'b00_0000_0001_0000,
                     OR_FP = 14'b00_0000_0010_0000,  // Other row - First Pixel
                     OR_OP = 14'b00_0000_0100_0000,  // Other row - Other Pixels
                     OR_LP = 14'b00_0000_1000_0000,  // Other row - Last Pixel
					 OR_Z0 = 14'b00_0001_0000_0000,
                     LR_FP = 14'b00_0010_0000_0000,  // Last row  - First Pixel
                     LR_OP = 14'b00_0100_0000_0000,  // Last row  - Other Pixels
                     LR_LP = 14'b00_1000_0000_0000,  // Last row  - Last Pixel
					 LR_Z0 = 14'b01_0000_0000_0000,
					 DONE =  14'b10_0000_0000_0000   // Send frame done here
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
		  inc_base_cnt = 1'b0;		  
		  en = 1'b0;
		  
		  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
			begin
				mb_rd_addr[cntlr_i] = '0;
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
				  if (pass_cnt < 2'd3)
					begin
						if(pass_cnt == '0)
						  begin
							  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
								begin								
									col_data[cntlr_i] = '0;       //Send Data
									mb_rd_addr[cntlr_i] = pu_col; //Issue memory read
								end						  
							  //Set State
							  cntlr_ns = R1_FP;
							  //Increment counters
							  inc_pu_col = 1'b1;
							  inc_pass_cnt = 1'b1;
							  //Enable the processors
							  en=1'b1;							  
						  end
						else
						  begin
							  //Send data
							  col_data[0] = '0;
							  col_data[1] = pu_data[0];
							  col_data[2] = pu_data[1];
							  col_data[3] = '0;
							  //Set State
							  cntlr_ns = R1_FP;
							  //Increment counter
							  inc_pu_col = 1'b1;
							  inc_pass_cnt = 1'b1;
							  //Issue memory read
							  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
								mb_rd_addr[cntlr_i] = pu_col;
							  //Enable the processors
							  en=1'b1;							  		
						  end
					end
				  else
					begin
						 //Send data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;
						//Set State
						cntlr_ns = R1_OP;
						//Increment counter
						inc_pu_col = 1'b1;
						inc_pass_cnt = 1'b1;
						//Issue memory read
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cntlr_i] = pu_col;
						//Enable the processors
						en=1'b1;
					end				  
			  end
			R1_OP:
			  begin
				  if(pu_col < (cfg_width-2'd2))
					begin
						//Send Data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;
						//Set State
						cntlr_ns = R1_OP;						
						//Increment counter
						inc_pu_col = 1'b1;
						//Issue memory read
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cntlr_i] = pu_col;
						//Enable the processors
						en=1'b1;
					end
				  else
					begin
						//Send Data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;
						//Set State
						cntlr_ns = R1_LP;						
						//Increment counter
						inc_pu_col = 1'b1;
						//Issue memory read
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cntlr_i] = pu_col;
						//Enable the processors
						en=1'b1;
					end				  
			  end
			R1_LP:
			  begin
				  if(pu_col == (cfg_width-2'd1))
					begin
						//Send Data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;
						//Set State
						cntlr_ns = R1_LP;						
						//Increment counter
						inc_pu_col = 1'b1;
						//Issue memory read
						for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
						  mb_rd_addr[cntlr_i] = pu_col;
						//Enable the processors
						en=1'b1;
					end
				  else
					begin				
						//Send Data
						col_data[0] = '0;
						col_data[1] = pu_data[0];
						col_data[2] = pu_data[1];
						col_data[3] = '0;					
						//Set State
						cntlr_ns = R1_Z0;
						//Enable the processors
						en=1'b1;						
					end				  						  
			  end
			R1_Z0:
			  begin
				  //Send final set of padding zeros
				  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
					col_data[cntlr_i] = '0;									  
				  //Set State
				  cntlr_ns = OR_FP;
				  //Mark memory is used
				  mem_used[0]=1'b1;
				  //Enable the processors
				  en=1'b1;							  
			  end
			OR_FP:
			  begin
				  if (pass_cnt < 2'd3)
					begin
						if(pass_cnt == '0)
						  begin
							  for(cntlr_i=0; cntlr_i<NM; cntlr_i=cntlr_i+1)
								//Send Data
								col_data[cntlr_i] = '0;
							  //Issue memory read
							  mb_rd_addr[cd0] = pu_col;
							  mb_rd_addr[cd1] = pu_col;
							  mb_rd_addr[cd2] = pu_col;											  
							  //Set State
							  cntlr_ns = OR_FP;
							  //Increment counters
							  inc_pu_col = 1'b1;
							  inc_pass_cnt = 1'b1;
							  //Enable the processors
							  en=1'b1;							  
						  end
						else
						  begin
							  //Send data
							  col_data[0] = pu_data[cd0];
							  col_data[1] = pu_data[cd1];
							  col_data[2] = pu_data[cd2];
							  col_data[3] = '0;
							  //Set State
							  cntlr_ns = OR_FP;
							  //Increment counter
							  inc_pu_col = 1'b1;
							  inc_pass_cnt = 1'b1;
							  //Issue memory read
							  mb_rd_addr[cd0] = pu_col;
							  mb_rd_addr[cd1] = pu_col;
							  mb_rd_addr[cd2] = pu_col;							  
							  //Enable the processors
							  en=1'b1;							  		
						  end
					end				  
				  else
					begin
						//Send data
						col_data[0] = pu_data[cd0];
						col_data[1] = pu_data[cd1];
						col_data[2] = pu_data[cd2];
						col_data[3] = '0;
						//Set State
						cntlr_ns = OR_FP;
						//Increment counter
						inc_pu_col = 1'b1;
						//Issue memory read
						mb_rd_addr[cd0] = pu_col;
						mb_rd_addr[cd1] = pu_col;
						mb_rd_addr[cd2] = pu_col;							  
						//Enable the processors
						en=1'b1;
					end // else: !if(pass_cnt == '0)
			  end // if (pass_cnt < 2'd3)
			OR_OP:
			  begin
				  cntlr_ns = IDLE;
			  end			
		  endcase // case (cntlr_ps)
	  end
	
							   
		  
	
	
	  
endmodule // cntl_unit
`endif
