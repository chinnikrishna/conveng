// Flip Flop with positive reset
`define ASYNC_RST_MSFF(q,i,clk,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<='0;\
		else q<=i;\
	end

// Flip Flop with positive reset and enable
`define EN_ASYNC_RST_MSFF(q,i,clk,en,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<='0;\
		else if(en) q<=i;\
	end

// Flip Flop with an initial state, pos reset and en
`define EN_RST_MSFFD(q,i,clk,en,init,rst)\
always_ff @(posedge clk, posedge rst)\
	begin\
		if(rst) q<=init;\
        else if(en) q<=i;\
	end
					 
		   
		
		   
		
