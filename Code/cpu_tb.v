//cpu module test bench.
//instruction memory is in the testbench

`include "cpu.v"
`include "instruction_cache.v"
`include "dcache.v"
`include "datamemory_new.v"
`include "instruction_mem.v"
 `timescale  1ns/100ps

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
	//reg [31:0] PC;
    reg [31:0] INSTRUCTION;
	wire WRITE,READ;
	wire [7:0]WRITEDATA;
	wire [7:0]ADDRESS;
	wire [7:0]READDATA;
	wire BUSYWAIT;
	wire [9:0]PC_address;
	assign PC_address={PC[9:2],2'b00};
    
    /* 
    ------------------------
     SIMPLE INSTRUCTION MEM
    ------------------------
    */
	wire i_membusywait,i_memread,inst_read,i_busywait;
	wire [127:0]i_memreaddata;
	wire [31:0]i_readdata;
	wire [5:0]i_memaddress;
	
	inst_cache myinstcache(CLK,RESET,i_membusywait,i_memreaddata,i_memaddress,PC_address,inst_read,i_busywait,i_readdata,i_memread);
	
	inst_memory myinstmem(
							CLK,
							i_memread,
							i_memaddress,
							i_memreaddata,
							i_membusywait
	);
   
    // TODO: Initialize an array of registers (8x1024) to be used as instruction memory
     reg [7:0] 	 instr_mem [1023:0];
    // TODO: Create combinational logic to fetch an instruction from instruction memory, given the Program Counter(PC) value 
    //       (make sure you include the delay for instruction fetching here)
	
/*	always @(PC)
	begin
	#2 
	INSTRUCTION[7:0] <=instr_mem[PC][1023:0] ; 
	INSTRUCTION[15:8] <=instr_mem[PC+1][1023:0] ; 
	INSTRUCTION[23:16] <=instr_mem[PC+2][1023:0] ; 
	INSTRUCTION[31:24] <=instr_mem[PC+3][1023:0] ; 
    end  */
	wire [31:0] newinstruction;
	assign newinstruction=i_readdata;
	
	always @(*)
	begin
	INSTRUCTION =newinstruction ; 
    end
	
	/*
    initial
    begin 
        // TODO: Initialize instruction memory with a set of instructions
        //       Hint: you can use something like this to load the instruction "loadi 4 0x19" onto instruction memory,
    
	


		{instr_mem[10'd3], instr_mem[10'd2], instr_mem[10'd1], instr_mem[10'd0]}     = 32'b00000000000000100000000000000101;  //loadi 2 0x05
		{instr_mem[10'd7], instr_mem[10'd6], instr_mem[10'd5], instr_mem[10'd4]}    = 32'b00000000000000110000000010101101; //loadi 3 0xAD
		{instr_mem[10'd11], instr_mem[10'd10], instr_mem[10'd9], instr_mem[10'd8]}   = 32'b00001011000000000000001000010010; //swi 2 0x12
		{instr_mem[10'd15], instr_mem[10'd14], instr_mem[10'd13], instr_mem[10'd12]} = 32'b00001001000001000000000000010010; //lwi 4 0x12
		{instr_mem[10'd19], instr_mem[10'd18], instr_mem[10'd17], instr_mem[10'd16]} = 32'b00001010000000000000001000000011; //swd 2 3
		{instr_mem[10'd23], instr_mem[10'd22], instr_mem[10'd21], instr_mem[10'd20]} = 32'b00001010000000000000010100000011; //swd 5 3
		{instr_mem[10'd27], instr_mem[10'd26], instr_mem[10'd25], instr_mem[10'd24]} = 32'b00001000000001000000000000000101; //lwd 4 5
		{instr_mem[10'd31], instr_mem[10'd30], instr_mem[10'd29], instr_mem[10'd28]} = 32'b00000010000001000000001000000011;//add 4 2 3
		{instr_mem[10'd35], instr_mem[10'd34], instr_mem[10'd33], instr_mem[10'd32]} = 32'b00000000000001000000000000000010; //loadi 4 0x02
		{instr_mem[10'd39], instr_mem[10'd38], instr_mem[10'd37], instr_mem[10'd36]} = 32'b00000000000000110000000000100110; //loadi 3 0x26
		{instr_mem[10'd43], instr_mem[10'd42], instr_mem[10'd41], instr_mem[10'd40]} = 32'b00000000000000010000000000000110; //loadi 1 0x06
		{instr_mem[10'd47], instr_mem[10'd46], instr_mem[10'd45], instr_mem[10'd44]} = 32'b00000000000000100000000000000100; //loadi 2 0x04
		{instr_mem[10'd51], instr_mem[10'd50], instr_mem[10'd49], instr_mem[10'd48]} = 32'b00001010000000000000001000000001; //swd 2 1
		{instr_mem[10'd55], instr_mem[10'd54], instr_mem[10'd53], instr_mem[10'd52]} = 32'b00001010000000000000010000000011; //swd 4 3  
	


		
    end   */
	
	wire mem_busywait,mem_read,mem_write,busywait_cpu;
	wire [5:0]mem_address;
	wire [31:0] mem_readdata,mem_writedata;
    assign busywait_cpu = BUSYWAIT||i_busywait;
    //call data memory and cpu
    cpu mycpu(PC, INSTRUCTION,busywait_cpu,READDATA,WRITE,READ,WRITEDATA,ADDRESS, CLK, RESET,inst_read);
	//data_memory my_mem(CLK,RESET,READ,WRITE,ADDRESS,WRITEDATA,READDATA,BUSYWAIT);
    dcache mycache(CLK,RESET,BUSYWAIT,
				READ,
				WRITE,
				WRITEDATA,
				READDATA,
				ADDRESS,
				mem_busywait,
				mem_read,
				mem_write,
				mem_writedata,
				mem_readdata,
				mem_address);
				
	data_memory mydmem(
	CLK,
    RESET,
    mem_read,
    mem_write,
    mem_address,
    mem_writedata,
    mem_readdata,
	mem_busywait
	);
	
    initial
    begin
    
        // generate files needed to plot the waveform using GTKWave
		$monitor($time ,"PC:%d\t",PC,"ins %b",INSTRUCTION ,"\tPC_address= %b",PC_address );
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
        
        CLK = 1'b1;
        RESET = 1'b0;
		#3
		RESET = 1'b1;
		#5
		RESET = 1'b0;
		#10000
		RESET = 1'b1;
		#10
		RESET = 1'b0;
		
        
        // TODO: Reset the CPU (by giving a pulse to RESET signal) to start the program execution
        
        // finish simulation after some time
        #10
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;
        

endmodule

