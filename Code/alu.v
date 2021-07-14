 `timescale  1ns/100ps
// Module name alu
module alu(DATA1, DATA2, RESULT, SELECT,ZERO);

//port declaration
input [7:0] DATA1, DATA2; //initialize 8bit values for input DATA1 and DATA2
input [2:0] SELECT;   //initialize 3bit values for input
output [7:0] RESULT;   //initialize 8bit values for output
output  ZERO;  //Choose branch or not

 reg [7:0] ALU_OUT; // declare a variable ALU_OUT that can hold its value 
 wire ZERO_value;
 
 assign RESULT=ALU_OUT; //Give variable ALU_OUT value to output
 assign ZERO =ZERO_value;
 wire [7:0]FORWARD, add_r ,and_r,or_r;
/*  
  always@(DATA1,DATA2,SELECT)
  begin
  #1 FORWARD= DATA2;
  end
  always@(DATA1,DATA2,SELECT)
  begin
 #2 add_r=DATA1+DATA2;
  end
  always@(DATA1,DATA2,SELECT)
  begin
  #1 and_r=DATA1&DATA2;
  end
  always@(DATA1,DATA2,SELECT)
  begin
   #1 or_r=DATA1|DATA2;
  end */
  
  
 assign #1 FORWARD= DATA2;
 assign #2 add_r=DATA1+DATA2;
 assign #1 and_r=DATA1&DATA2;
 assign #1 or_r=DATA1|DATA2;
  
 

 //2second delay added
 always @(FORWARD,add_r,and_r,or_r,SELECT)
 
	begin
		case(SELECT)
	
		3'b000: //FORWARD loadi, mov 
		
		ALU_OUT=FORWARD;
		
		3'b001: //ADDITION add, sub
		 ALU_OUT=   add_r;
		
		3'b010: //AND
		 ALU_OUT= and_r;

		3'b011: //OR
		 ALU_OUT=  or_r;
		
		default: ALU_OUT=8'bx; //remaining bits are reserved
			//$display(" select value not allowed"); //remaining bits are reserved
			
		endcase
	
	end
	
//if the result is zero ,Zero signal must be high

	wire  OUT1,OUT2,OUT3,OUT4,OUT5,OUT6,OUT7;
	wire [7:0]IN1,IN2;
	assign IN1=RESULT;
	assign IN2=RESULT;

	or n_gate0(OUT1, IN1[0], IN1[1]); 
	or n_gate1(OUT2, IN1[2], OUT1);
	or n_gate2(OUT3, IN1[3], OUT2);
	or n_gate3(OUT4, IN1[4], OUT3);
	or n_gate4(OUT5, IN1[5], OUT4);
	or n_gate5(OUT6, IN1[6], OUT5); 
	or n_gate5(OUT7, IN1[7], OUT6);
	not (ZERO_value,OUT7);
 


	
endmodule	


