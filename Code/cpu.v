`include "mux.v"
`include "alu.v"
`include "reg_file.v"
`include "Adder.v"
`include "PCadder.v"
`include "Offset_calculator.v"
 `timescale  1ns/100ps

module cpu(PC, INSTRUCTION,BUSYWAIT,READDATA,WRITE,READ,WRITEDATA,ADDRESS, CLK, RESET,inst_read);

	
	input CLK,RESET,BUSYWAIT;
	input [31:0]INSTRUCTION;
	input [7:0]READDATA;
	output [31:0] PC;
	output reg WRITE,READ;
	output [7:0]WRITEDATA;
	output [7:0]ADDRESS;
	
	output inst_read;
	//input i_busywait;

	
	reg [31:0] PC;
	
	//increment pc in positive clk edge if reset is not 1
	//if reset is 1,then pc = -4 and again when it executes (-4)+4
	//give correct pc value
	//pc update takes #1 delay and  adder has a latency of two time units (#2)
	always @(RESET)
	begin
		if (RESET==1)
		begin
			#1	PC <= -32'd4; //-4 assigned
			JUMP  =1'b0;
			BNE   =1'b0;
			BRANCH=1'b0;
		end
	end
	

	
	//instruction decode part.#1 delay added 
	
	reg [7:0]OPCODE; // opcode defines what is the instruction type
	reg WRITEENABLE,BRANCH,JUMP,BNE;
	reg [7:0] IMMEDIATE,incr; 
	reg [2:0] ALUOP; //to give control signals to alu
	reg mux1; //to give control signal to select complement or not
	reg mux2; //to give control signal to select immidiate value or not
	reg mux3; //to give control signal to select what is going to write in registerfile
	reg [2:0] READREG1,READREG2,WRITEREG; //to store address of source1 source2 destination registers
	wire [7:0] complement; //to get 2s complement for substraction operation
	wire [7:0] ALURESULT,REGOUT2,REGOUT1,out1,operand1; //define the outputs of alu registerfile mux1 and mux 2
	wire ZERO;
	wire [31:0] PCout,PC3;
	wire [7:0]IN; //the value to be written in register file
	reg inst_read;
	
	always @(*)
	begin
		if (PC!= -4)
		begin
		inst_read=1; //when pc=-4 instruction memory read can not perform
		end
		else
		begin
		inst_read=0;
		end
	end
	
	/*---------------------------------------------------
	in given 32 bit address can be  decoded in to 4 parts
	OPCODE=INSTRUCTION[31:24]
	Destination=INSTRUCTION[23:16]
	source1=INSTRUCTION[15:8]
	source2=INSTRUCTION[7:0]
	but here addresses are 3 bit values
	-----------------------------------------------------*/
	
	
	always @(INSTRUCTION)
	begin
		OPCODE=INSTRUCTION[31:24];
		WRITEREG= INSTRUCTION[18:16];
		READREG2 = INSTRUCTION [2:0];
		IMMEDIATE   =INSTRUCTION [7:0];
		READREG1 = INSTRUCTION [10:8]; 
		incr =INSTRUCTION[23:16];
		READ=1'b0;
		WRITE=1'b0;
	
	
		//decode according to opcode
			case(OPCODE)
			8'b00000010: #1  //addition operation
			begin
			
				ALUOP = 3'b001;
				WRITEENABLE =1'b1;
				mux1 = 1'b0;
				mux2 = 1'b1;
				mux3 = 1'b0;
				JUMP = 1'b0;
				BRANCH = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end
			
			8'b00000011: #1  //substraction operation
			
			begin
				WRITEENABLE =1'b1;
				ALUOP = 3'b001;
				mux1 =1'b1;
				mux2 =1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b0;
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end	
			
			8'b00000100: #1 //and operation
			
			begin
				WRITEENABLE =1'b1;
				ALUOP = 3'b010;
				mux1 =1'b0;
				mux2 = 1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b0;
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end	
			
			8'b00000101: #1 //or operation
			
			begin
				WRITEENABLE =1'b1;
				ALUOP = 3'b011;
				mux1 =1'b0;
				mux2 = 1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b0;
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end	
			
			8'b00000001: #1//mov operation
			
			begin
				WRITEENABLE =1'b1;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b0;
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end	
			
			8'b00000000: #1 //loadi operation
			
			begin
			    WRITEENABLE =1'b1;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b0;
				mux3 = 1'b0;
				BRANCH = 1'b0;
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end	
			
			8'b00000111: #1 //beq operation
			
			begin
			    WRITEENABLE =1'b0;
				ALUOP = 3'b001;
				mux1 = 1'b1;
				mux2 = 1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b1; //signal for beq
				JUMP = 1'b0;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
				
				
			end	
			
			8'b00000110: #1 //jump operation
			
			begin
			    WRITEENABLE =1'b0;
				mux1 = 1'b0;
				mux2 = 1'b0;
				mux3 = 1'b0;
				JUMP = 1'b1; //signal for jump
				BRANCH = 1'b0;
				ALUOP = 3'b000;
				BNE = 1'b0;
				READ = 1'b0;
				WRITE = 1'b0;
			end
			
			8'b00010101: #1 //bne operation
			
			begin
			    WRITEENABLE =1'b0;
				ALUOP = 3'b001;
				mux1 = 1'b1;
				mux2 = 1'b1;
				mux3 = 1'b0;
				BRANCH = 1'b0; 
				JUMP = 1'b0;
				BNE = 1'b1;//signal for bne
				READ = 1'b0;
				WRITE = 1'b0;
				
				
			end
			
			8'b00001001: #1 //lwi operation
			
			begin
			    WRITEENABLE =1'b1;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b0;
				mux3 = 1'b1;
				BRANCH = 1'b0; 
				JUMP = 1'b0;
				BNE = 1'b0;//signal for bne
				READ = 1'b1;
				WRITE = 1'b0;
				
			end
			
			8'b00001000: #1 //lwd operation
			
			begin
			    WRITEENABLE =1'b1;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b1;
				mux3 = 1'b1;
				BRANCH = 1'b0; 
				JUMP = 1'b0;
				BNE = 1'b0;//signal for bne
				READ = 1'b1;
				WRITE = 1'b0;
				
			end
			
			8'b00001011: #1 //swi operation
			
			begin
			    WRITEENABLE =1'b0;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b0;
				mux3 = 1'b1;
				BRANCH = 1'b0; 
				JUMP = 1'b0;
				BNE = 1'b0;//signal for bne
				READ = 1'b0;
				WRITE = 1'b1;
				
			end
			
			8'b00001010: #1 //swd operation
			
			begin
			    WRITEENABLE =1'b0;
				ALUOP = 3'b000;
				mux1 = 1'b0;
				mux2 = 1'b1;
				mux3 = 1'b1;
				BRANCH = 1'b0; 
				JUMP = 1'b0;
				BNE = 1'b0;//signal for bne
				READ = 1'b0;
				WRITE = 1'b1;
				
			end
			
		endcase

	
	end	
	
	//Offset_calculator module use to get the number of instructions to be jumped(offset)
	//offset_t2 is the offset value that calculted from instructions
    //if branch or jump instruction 2 time units delay added.
	//this is parallel to instruction Decode
	//if beq instruction ,Register read also parallel to this
	wire [31:0]offset_t1,offset_t2;
	Offset_calculator myoffset(incr,offset_t1);
	
	assign #2  offset_t2=offset_t1;

 	//in substraction operation 2's complement of the second operand is add to first operand
	//here complement created seperately
	assign #1 complement[7:0] = ~REGOUT2[7:0]+1'b1 ; 
	
	reg_file myreg(IN,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2,WRITEENABLE,CLK,RESET,BUSYWAIT); //use registerfile
	mux_2x1 reg_mux1(REGOUT2,complement,mux1,out1); //choose data2 or its complement
	mux_2x1 reg_mux2(IMMEDIATE,out1,mux2,operand1); //choose immidiate value or data2
	alu myalu(REGOUT1, operand1, ALURESULT, ALUOP,ZERO); //use alu 
	mux_2x1 reg_mux3(ALURESULT,READDATA,mux3,IN);   //choose ALURESULT from alu or READDATA from data memory
	
	/*  
	if branch signal and ZERO signal 1 or jump signal 1 or branch not equal signal(BNE)1 and ZERO flag low
	then there must be increment more than 4.Itis calculated in myadd(module adder)
	if not PC+4.
	*/
	adder myadd(BNE,BRANCH,JUMP,ZERO,offset_t2,PCout);
	
	PCadder add(PC,PC3); //adder module to set PC +4 value
	
	//define data for datamemory module
	assign ADDRESS =ALURESULT;
	assign WRITEDATA = REGOUT1;
	
	
	
	wire [31:0]PC2,PC4;
	
    //PC4 value is the offset for branch or jump instruction.
	//PC2 is PC+4 value
	
	assign  PC4=PCout; 
	assign #1 PC2 = PC3; //PC+4 vlaue
	
	/*--------------------------------------------------------------------------------------------------------
	As PC is Synchronized to positive clk edge the increment will done only at 
	positive clock edge.	
	----------------------------------------------------------------------------------------------------------*/
	
	always @(posedge CLK)
	begin
	#1
		if (RESET==0&& BUSYWAIT==0 )
		begin
			//#1  //PC update delay
			 PC <= PC2+PC4;
		end
	end
	
endmodule   