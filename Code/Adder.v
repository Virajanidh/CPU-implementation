 `timescale  1ns/100ps
module adder(BNE,BRANCH,JUMP,ZERO,incr,PCout);

input BRANCH,JUMP,ZERO,BNE; 
input [31:0]incr;
output [31:0]PCout;

reg [7:0] out5;
reg [9:0] offset;
reg [31:0]offset_t =32'b0; //register to store PCout value

reg [31:0] out10;

wire out1,out2,out3,out4,out6;

/*out4=1 when -> BRANCH and ZERO signals are high ,
              -> BNE signal is high and ZERO signal is low ,
			  -> JUMP signal is high  */

and a1(out1,BRANCH,ZERO);
not not1(out6,ZERO);
and a2(out2,BNE,out6);
or or1(out3,out1,out2);
or or2(out4,out3,JUMP);

always @(*)
begin

	out10=$signed(out4);
	offset_t= out10&incr ;
	

end

assign  PCout =$signed(offset_t);


endmodule



