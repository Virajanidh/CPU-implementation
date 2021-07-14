 `timescale  1ns/100ps
 
 module inst_cache (clock,reset,i_membusywait,i_memreaddata,i_memaddress,PC_address,read,i_busywait,i_readdata,i_memread);
  input clock,reset,i_membusywait,read;
  input[9:0] PC_address;
  input[127:0]i_memreaddata;
  output reg [5:0]i_memaddress;
  output reg [31:0]i_readdata;
  output reg i_busywait;
  output reg i_memread;
  
  	reg [127:0] inst_cachedata[7:0]; //data block array 127x8 size
	reg [2:0] tag_array[7:0]; //tag array 3x8 size
	reg [2:0] index_array[7:0]; //index array 3x8 size
	reg valid_array[7:0]; //valid bit . 1 bit for each
	reg [1:0]offset;
	reg [2:0] index,tag;
	reg [127:0]datablock;
	
	
	integer i;
	always @(reset)
	begin
		if (reset==1)
		begin
			for(i=0;i<8;i=i+1)
			begin
			
			//in reset valid bit array tag_array  cach_data set to 0.
				valid_array[i]=1'b0;
				tag_array[i][2:0]=3'b000;
				inst_cachedata[i][127:0]=128'd0;
			
			end
			i_busywait = 0;
			
			
		end
	end
	
	always @(*)
	begin
		offset=  PC_address[3:2]; //decode offset from address
		index =  PC_address[6:4]; //decode index from address 
		tag   =  PC_address[9:7]; //decode tag from address 
		#1 datablock =inst_cachedata[index][127:0]; //#1 time unit when extracting  stored dataword values
	
	end
	
	wire [2:0] in1,in2;
	wire v,tagcom,hit;
	assign in1=tag;
	//#1 time unit when extracting  stored valid bit and tag values
	assign #1 in2=tag_array[index][2:0];
	assign #1 v=valid_array[index];
	 // artificial latency of #1 time unit for the tag comparison 
	assign #1 tagcom=(in2==in1)? 1 : 0;   //if tagcom=1 then tag is same.tagcom=0 tag is not equal (compare tag given by cpu and tag in cache)
    assign hit= tagcom && v;
	
	//handdle hit
/*------------------------------------------------------------------------------
if read or write happens busywait signal will high asynchronously.
but when detect as hit, the busywait signal will low at positive clock edge.
------------------------------------------------------------------------------*/
	always @(*)
	begin
		if(read)
			i_busywait=1;
		else
			i_busywait=0;
	
	end
	
	always @(posedge clock)
	begin
		if(hit)
		begin
		i_busywait=0;
		end
	end
	
	//Reading 

	//choose read data word
	//artificial latency of #1 time unit in the data word selection
	//Cache selects the requested data word from the block based on the Offset, and send
    //the data word to the CPU asynchronously
	//no affect because of early assigning as busywait is high until it determines as a hit

	
	
	reg [31:0] i_readdata_1;
	
	always @( offset,datablock)
	begin
	
			case(offset)
			2'b11 :
			#1	i_readdata_1=datablock[127:96];
			2'b10:
			#1	i_readdata_1=datablock[95:64];
			2'b01:
			#1	i_readdata_1=datablock[63:32];
			2'b00:
			#1	i_readdata_1=datablock[31:0];
			
			endcase
		
	end
	always @(hit,read,i_readdata_1)
	begin
		if(hit&&read)
		begin
		i_readdata=i_readdata_1;
		end
	end
	
	

	
    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001,C_UPDATE=3'b011;
    reg [2:0] state, next_state; 
	
	/*-------------------------------------------------------------------------------------------
	IDLE	  -> initial state
	MEM_READ  -> read data from memory when cache having miss
	C_UPDATE  -> after hit is resolved  the cache should write the fetched data block into the 
					indexed cache entry and update the tag
	--------------------------------------------------------------------------------------------*/

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read) && !hit)  
                    next_state = MEM_READ;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!i_membusywait)
                    next_state = C_UPDATE;
                else    
                    next_state = MEM_READ;
			
			C_UPDATE:  
                    next_state =IDLE;
                
					
            
        endcase
    end
	
	 // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                i_memread= 0;
                i_memaddress = 8'dx;
               i_busywait = 0;
            end
         
            MEM_READ: 
            begin
                i_memread = 1;
                i_memaddress = {tag, index};
               i_busywait = 1;
            end

			C_UPDATE:
			begin
				i_memread = 0;
				i_busywait = 1;
				//set the updated tag into cache
				// write data sent by instruction cache memory to datablock
				//1 time unit writing operation latency added
				//set valid bit 1 and dirty bit 0

				#1
				
				tag_array[index][2:0]=tag;
				inst_cachedata[index]=  i_memreaddata;
				valid_array[index]=1; //set valid bit
				
			end
			
            
        endcase
    end
	
	    // sequential logic for state transitioning 
    always @(posedge clock, reset)
    begin
        if(reset)
            state = IDLE;
        else
            state = next_state;
    end

    /* Cache Controller FSM End */

endmodule