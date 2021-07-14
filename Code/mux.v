 `timescale  1ns/100ps
	//Multiplexer
	module mux_2x1(in0,in1,sel,out);
	
	//port declaration
	input [7:0] in0,in1;
	input sel;
	output [7:0] out; 
 
	reg out; //interenal signal
	
	
	always @ (in0,in1,sel) 
	begin
	
		if(sel == 1'b0)begin	
			out = in0;
		end else begin
			out = in1;
		end
	
	end 
	
	endmodule
	
/*	
	module mux_4x1(in0,in1,in2,in3,sel,out);
	
	//port declaration
	input [7:0] in0,in1,in2,in3;
	input [1:0]sel;
	output [7:0] out; 
 
	reg  out; //interenal signal
	
	
	always @ (in0,in1,sel) 
	begin
	
		case(sel)
		begin
		2'b00:
			out=in0;
		2'b01:
			out=in1;
		2'b10:
			out=in2;
		2'b11:
			out=in3;
		endcase
	
	end 
	
	endmodule
*/
