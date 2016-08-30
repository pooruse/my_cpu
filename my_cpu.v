`timescale 1ns/1ps
`define PC_SIZE 14
`define INS_SIZE 32
`define PROGRAM_MEM_SIZE 4096
`define SRAM_BITWIDTH 16

`define LOAD 4'h01
`define STORE 4'h02
`define FETCH 4'h03
`define JUMP 4'h04
`define ADD 4'h05
`define ADDCY 4'h06
`define SUB 4'h07
`define SUBCY 4'h08
`define OR 4'h09
`define AND 4'h0A
`define XOR 4'h0B
`define COMPARE 4'h0C
`define TEST 4'h0D
`define INPUT 4'h0E
`define OUTPUT 4'h0F

`define INS_DATA 3'b000 
`define INS_REG 3'b001 
`define INS_ADDR 3'b010 
`define INS_ADDR_REG 3'b011 
`define INS_INPUT 3'b100 

`define JUMP_N  2'b00 
`define JUMP_Z  2'b01 
`define JUMP_C  2'b10 
`define JUMP_ZC 2'b11 

/**
 *  @my_cpu
 */
module my_cpu(

	//
	//  io control
	//
	input [7:0]io_input,
	output reg [7:0]io_input_id,
	output reg [7:0]io_output,
	output reg [7:0]io_output_id,
	
	input [`INS_SIZE-1:0]instruction,
	output reg [`PC_SIZE-1:0]PC,
	
	//
	//  memory control
	//
	output reg [`SRAM_BITWIDTH-1:0]A,
	input [7:0]data_in,
	output reg [7:0]data_out,
	output reg cs,
	output reg we,
	
	input clk,
	input rst
);

reg [7:0]S[15:0];
wire [3:0]w_instruction;
wire [`PC_SIZE-1:0]data_src;
wire [`PC_SIZE-1:0]data_dst;
reg [15:0]result;

assign w_instruction = instruction[31:28];
assign data_src = instruction[13:0];
assign data_dst = instruction[27:14];

/**
 * program counter
 */
reg [`PC_SIZE-1:0]jump_addr;
reg jump_en;
always @(posedge clk or negedge rst) begin
	if(rst == 0) begin
		PC <= 0;
	end else begin
		if(jump_en == 0) begin
			PC <= PC + `PC_SIZE'b1;
		end else begin
			PC <= jump_addr;
		end
	end
end

/**
 *  instruction decoder
 */
reg [7:0]operand1;
reg [7:0]operand2;
always @(*) begin
	A = 0;
	operand1 = 0;
	operand2 = 0;
	case(data_src[10:8])
	
		`INS_DATA: operand1 = data_src[7:0];
		`INS_REG: operand1 = S[data_src[7:0]];
		`INS_ADDR: begin A = data_src[7:0]; operand1 = data_in; end
		`INS_ADDR_REG: begin A = S[data_src[7:0]]; operand1 = data_in; end
		`INS_INPUT: operand1 = io_input;
	endcase
	
	case(data_dst[9:8])
		`INS_DATA: operand2 = data_dst[7:0];
		`INS_REG: operand2 = S[data_dst[7:0]];
		default: operand2 = 0;
	endcase 
	
end

/**
 *  ALU
 */

always @(*) begin
	case(w_instruction) 
		`LOAD: 		result = operand1;
		`STORE: 		result = operand1;
		`FETCH: 		result = operand1;
		`JUMP: 		result = operand1;
		`ADD: 		result = operand2 + operand1;
		`ADDCY: 		result = operand2 + operand1 + C;
		`SUB: 		result = operand2 - operand1;
		`SUBCY: 		result = operand2 - operand1 - C;
		`OR: 			result = operand2 | operand1;
		`AND: 		result = operand2 & operand1;
		`XOR: 		result = operand2 ^ operand1;
		`COMPARE: 	result = operand2 - operand1;
		`TEST: 		result = operand2 - operand1;
		`INPUT: 		result = operand1;
		`OUTPUT: 	result = operand1;
		default: 	result = 0;
	endcase
end

/**
 *  data redirection circuit
 */
reg C;
reg Z;
integer i;
always @(posedge clk or negedge rst) begin
	if(rst == 0) begin
		cs <= 1;
		we <= 1;
		data_out <= 0;
		jump_addr <= 0;
		jump_en <= 0;
		C <= 0;
		Z <= 0;
		
		for(i=0;i<16;i=i+1) S[i] <= 0;
		
	    io_input_id <= 0;
	    io_output <= 0;
	    io_output_id <= 0;
		
	end else begin
	
		C <= result[8];
		Z <= (result == 0);
		
		case(w_instruction)
			`LOAD: begin
				S[data_dst[7:0]] <= result[7:0];
				cs <= 0;
				we <= 1;
			end
			`STORE: begin
				data_out <= result[7:0];
				cs <= 0;
				we <= 0;
			end
			`FETCH: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`JUMP: begin
				case(data_src[12:11])
					`JUMP_N: jump_addr <= result[`PC_SIZE-1:0];
					
					`JUMP_Z: begin
						if(Z==1) begin
							jump_addr <= result[`PC_SIZE-1:0];
						end else begin
							jump_addr <= PC;
						end
						
					end
					
					`JUMP_C: begin
						if(C==1) begin
							jump_addr <= result[`PC_SIZE-1:0];
						end else begin
							jump_addr <= PC;
						end
						
					end
					
					`JUMP_ZC: begin
						if({Z,C}==2'b11) begin
							jump_addr <= result[`PC_SIZE-1:0];
						end else begin
							jump_addr <= PC;
						end
						
					end
				endcase
				
				jump_en <= 1;
			end
			`ADD: begin
				S[data_dst[7:0]] <= result[7:0];
				
			end 
			`ADDCY: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`SUB: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`SUBCY: begin
				S[data_dst[7:0]] <= result[7:0];
			end  
			`OR: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`AND: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`XOR: begin
				S[data_dst[7:0]] <= result[7:0];
			end 
			`INPUT: begin
				S[data_dst[7:0]] <= result[7:0];
				io_input_id <= operand2;
			end
			`OUTPUT: begin
				io_output_id <= operand2;
				io_output <= result[7:0];
			end
			`COMPARE: begin end
			`TEST: begin end
			default: begin
			
			end
		endcase
	end
end
endmodule 

