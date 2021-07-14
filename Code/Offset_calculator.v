 `timescale  1ns/100ps
module Offset_calculator(incr,offset_t1);

	input [7:0]incr;
	output [31:0] offset_t1;
	reg [9:0] offset;
	reg [31:0]offset_t =32'b0;
	
	
	always @(*)
	begin
		offset ={incr,2'b00}; //shift left by 2
		offset_t =  $signed(offset) ; //sign extend to 32 bits
	end
	//return calculated offset value
	assign offset_t1=offset_t;
endmodule