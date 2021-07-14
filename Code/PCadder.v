 `timescale  1ns/100ps
module PCadder(PC,PC3);


	input [31:0]PC;
	output [31:0]PC3;
	reg [31:0]PC3_t;

	always @ (*)
	begin
	
		PC3_t =PC+32'd04; //update PC + 4 +offset
	
	end
//PC+4 update has 1 time units delay.It is parallel to instruction memory read
	assign  PC3=PC3_t; 

endmodule