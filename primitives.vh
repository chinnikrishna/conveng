// DFlip Flop with positive sync reset
`define SYNC_RST_MSFF(q,i,clk,rst)\
always_ff @(posedge clk)\
	begin\
		if(rst) q<='0;\
		else q<=i;\
	end

// DFlip Flop with positive sync reset and enable
`define EN_SYNC_RST_MSFF(q,i,clk,en,rst)\
always_ff @(posedge clk)\
	begin\
		if(rst) q<='0;\
		else if(en) q<=i;\
	end
	
// DFlip Flop with positive async reset
`define ASYNC_RST_MSFF(q,i,clk,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<='0;\
		else q<=i;\
	end

// DFlip Flop with positive async reset and enable
`define EN_ASYNC_RST_MSFF(q,i,clk,en,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<='0;\
		else if(en) q<=i;\
	end

// DFlip Flop with an initial state, pos reset and en
`define EN_RST_MSFFD(q,i,clk,en,init,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<=init;\
        else if(en) q<=i;\
	end
					 
		   
		
		   
		
