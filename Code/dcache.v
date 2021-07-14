//for the better performance on PC update in cpu the latency of 1 time unit is changed the place from
// after cheking busywait signal add delay and update PC to before cheking busywait signal add delay and update PC
 `timescale  1ns/100ps

module dcache (clock,reset,busywait,
				read,
				write,
				writedata,
				readdata,
				address,
				mem_busywait,
				mem_read,
				mem_write,
				mem_writedata,
				mem_readdata,
				mem_address);
				
	input clock,reset,read,write,mem_busywait;
	input [7:0] writedata,address;
	input [31:0] mem_readdata;
	output busywait;
	output reg mem_read,mem_write;
	output reg [31:0] mem_writedata;
	output reg [5:0] mem_address;
	output reg [7:0]readdata;
	
	wire hit,dirty;
	reg [1:0] offset;
	reg [2:0] index;
	reg [2:0] tag;
	reg [31:0] cach_data[7:0]; //data block array 31x8 size
	reg [2:0] tag_array[7:0]; //tag array 3x8 size
	reg [2:0] index_array[7:0]; //index array 3x8 size
	reg valid_array[7:0]; //valid bit . 1 bit for each
	reg dirty_array[7:0]; //dirty bit . 1 bit for each
	reg [7:0] dataword;
	reg busywait_1,busywait_reg;
	reg update_cache;
	reg [31:0] datablock;
	
	assign busywait=busywait_reg;
	
	integer i;
	
	always @(reset)
	begin
		if (reset==1)
		begin
			for(i=0;i<8;i=i+1)
			begin
			
			//in reset valid bit array tag_array dirty_array cach_data set to 0.
				valid_array[i]=1'b0;
				dirty_array[i]=1'b0;
				tag_array[i][2:0]=3'b000;
				cach_data[i][31:0]=32'd0;
			
			end
			busywait_reg = 0;
			
			
		end
	end
	
	
	always @(address)
	begin
		offset=  address[1:0]; //decode offset from address
		index =  address[4:2]; //decode index from address 
		tag   =  address[7:5]; //decode tag from address 
		#1 datablock =cach_data[index][31:0]; //#1 time unit when extracting  stored dataword values
	
	end
	
	assign #1 dirty =  dirty_array[index];  //#1 time unit when extracting  stored dirty bit values
	wire [2:0] in1,in2;
	wire v,tagcom;
	assign in1=tag;
	//#1 time unit when extracting  stored valid bit and tag values
	assign #1 in2=tag_array[index][2:0];
	assign #1 v=valid_array[index];
	
 // artificial latency of #1 time unit for the tag comparison 
	assign #0.9 tagcom=(in2==in1)? 1 : 0;   //if tagcom=1 then tag is same.tagcom=0 tag is not equal (compare tag given by cpu and tag in cache)
    assign hit= tagcom && v;
	
//handdle hit
/*------------------------------------------------------------------------------
if read or write happens busywait signal will high asynchronously.
but when detect as hit, the busywait signal will low at positive clock edge.
------------------------------------------------------------------------------*/
	always @(address,read,write)
	begin
		if(read||write)
			busywait_reg=1;
		else
			busywait_reg=0;
	
	end
	
	always @(posedge clock)
	begin
		if(hit)
		begin
		busywait_reg=0;
		end
	end

//Reading & writing

	//choose read data word
	//artificial latency of #1 time unit in the data word selection
	//Cache selects the requested data word from the block based on the Offset, and send
    //the data word to the CPU asynchronously
	//no affect because of early assigning as busywait is high until it determines as a hit
/*	wire [7:0]readdata_1;
	assign #1 readdata_1= ((offset==2'b01)&&read)? datablock[15:8]:
						((offset==2'b10)&&read)? datablock[23:16]:
						((offset==2'b11)&&read)? datablock[31:24]: datablock[7:0];
	always @(*)
	begin
		if(hit)
		begin
		readdata=readdata_1;
		end
	end  */
	always @(*)
	begin
		if(hit)
		begin
		#1
		case(offset)
			2'b00:readdata=cach_data[index][7:0];
			2'b01:readdata=cach_data[index][15:8];
			2'b10:readdata=cach_data[index][23:16];
			2'b11:readdata=cach_data[index][31:24];
			endcase
		end
	
	end
	
	//cache controller writes the data at the
    //positive edge of the clock (at the start of the next clock cycle)
	//set dirty bit one since write on cache when hit high
	
	always @(posedge clock,hit)
	begin
	
		if(write && hit )
		begin
			#1
			dirty_array[index]=1; //set dirty bit
			case(offset)
			2'b01:
				cach_data[index][15:8]=writedata;
			2'b10:
				cach_data[index][23:16]=writedata;
			2'b11:
				cach_data[index][31:24]=writedata;
			default :
				cach_data[index][7:0]=writedata;
			endcase
			
		end
		
	end
	
	
	
    /*
    Combinational part for indexing, tag comparison for hit deciding, etc.
    ...
    ...
    */
    

    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001,MEM_WRITE=3'b010 ,C_UPDATE=3'b011;
    reg [2:0] state, next_state; 
	
	/*-------------------------------------------------------------------------------------------
	IDLE	  -> initial state
	MEM_READ  -> read data from memory when cache having miss
	MEM_WRITE -> when dirty bit is 1, the data in datablock of cache is write to memory in a miss
	C_UPDATE  -> after hit is resolved  the cache should write the fetched data block into the 
					indexed cache entry and update the tag
	--------------------------------------------------------------------------------------------*/

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty && !hit)  
                    next_state = MEM_READ;
                else if ((read || write) && dirty && !hit)
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = C_UPDATE;
                else    
                    next_state = MEM_READ;
			MEM_WRITE:
                if (!mem_busywait)
                    next_state = MEM_READ;
                else    
                    next_state = MEM_WRITE;
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
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 32'dx;
                busywait_reg = 0;
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                busywait_reg = 1;
            end
			 MEM_WRITE: 
            begin
                mem_read = 0;
                mem_write = 1;
                mem_address = {tag, index};
                mem_writedata = datablock;
                busywait_reg = 1;
            end
			C_UPDATE:
			begin
				mem_read = 0;
                mem_write = 0;
				busywait_reg = 1;
				//set the updated tag into cache
				// write data sent by data memory to datablock
				//1 time unit writing operation latency added
				//set valid bit 1 and dirty bit 0

				#1
				
				tag_array[index][2:0]=tag;
				//cach_data[index]=  mem_readdata;
		
				cach_data[index][7:0]=  mem_readdata[7:0];
				cach_data[index][15:8]=  mem_readdata[15:8];
				cach_data[index][23:16]=  mem_readdata[23:16];
				cach_data[index][31:24]=  mem_readdata[31:24]; 
		
				valid_array[index]=1; //set valid bit
				dirty_array[index]=0;
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