 `timescale  1ns/100ps
module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET,busywait) ;

	input [7:0] IN; //initialize 8bit values for input IN
	input [2:0] INADDRESS, OUT1ADDRESS, OUT2ADDRESS;  //initialize 3bit values for addresses
	input WRITE, CLK, RESET,busywait; //sensitive signals
	output [7:0] OUT1,OUT2; //initialize 8bit values for outputs

	reg [7:0] 	 regfile [0:7];// Register file storage
	integer i;

	 //registers identified by OUT1ADDRESS and OUT2ADDRESS are read and 
	 //the values are loaded onto OUT1 and OUT2 respectively 
	 //2second delay added
	assign #2 OUT1 = regfile[OUT1ADDRESS];
	assign #2 OUT2 = regfile[OUT2ADDRESS];
	
	//reset is edge triggered .2Second reset delay added
	always @(RESET) begin
		if (RESET==1)begin
			#2;
			for (i = 0; i < 8; i = i + 1) begin
				regfile[i] <=8'b0;
			end
		end 
	end
	
	// write to egister file.2 Second write delay added
	//write is level triggered
	//write is done Only at positive edge of the clk and WRITE signal enabaled 
	// written to the input register specified by the INADDRESS
	always @(posedge CLK) begin
		#1	if ((WRITE==1) &&(RESET==0)&&(busywait==0))begin
				regfile[INADDRESS] <=IN ;
			end
	end
	


	
endmodule	
