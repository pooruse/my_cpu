`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:25:00 02/05/2015 
// Design Name: 
// Module Name:    my_cpu_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

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

module my_cpu_tb;

reg [7:0]io_input;
wire [7:0]io_input_id;
wire [7:0]io_output;
wire [7:0]io_output_id;

reg [`INS_SIZE-1:0]instruction;
wire [`PC_SIZE-1:0]PC;

reg [7:0]data_in;
wire [7:0]data_out;
wire [`SRAM_BITWIDTH-1:0]A;
wire cs;
wire we;

reg clk;
reg rst;

my_cpu u1(
	.io_input(io_input),
	.io_input_id(io_input_id),
	.io_output(io_output),
	.io_output_id(io_output_id),
	
	.instruction(instruction),
	.PC(PC),
	
	.A(A),
	.data_in(data_in),
	.data_out(data_out),
	.cs(cs),
	.we(we),
	
	.clk(clk),
	.rst(rst)
);

task send_instruction;
input [`INS_SIZE-1:0] ins;
	@(negedge clk) instruction = ins;
endtask


always #1 clk = ~clk;

initial begin
	rst = 0;
	data_in = 8'hCC;
	clk = 0;
	io_input = 8'hAA;
	instruction = 8'h0;
	
	#100; rst =1;
	send_instruction({`LOAD, 1'b0, `JUMP_N,`INS_DATA, 8'b0, 1'b0, `JUMP_N,`INS_DATA, 8'd0 });
	send_instruction({`ADD , 1'b0, `JUMP_N,`INS_DATA, 8'b0, 1'b0, `JUMP_N,`INS_DATA, 8'd3 });
	
	
	#1000000 $finish;
end
endmodule

