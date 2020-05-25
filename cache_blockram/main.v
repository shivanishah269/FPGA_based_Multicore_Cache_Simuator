`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2020 11:22:27
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main(clk,memory_trace,cache_hit,cache_miss);

input clk;
input [15:0] memory_trace;
output [15:0] cache_hit,cache_miss;

parameter way = 1;
parameter block_size_byte = 64;
parameter cache_size_byte = 16*1024;

parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
parameter set = cache_size_byte/(block_size_byte*way); 
parameter set_index = $rtoi($ln(set)/$ln(2));

// variables to divide address in tag, index and offset
wire [31:0] mem_addr;
wire [31-set_index-block_offset_index:0] tag;
wire [set_index-1:0] index;
wire [block_offset_index-1:0] block_offset;
reg [15:0] prev_mem_trace;
wire reset;

//find_data variables
wire found_in_cache;

//request_block variables
wire [(block_size_byte*8)-1:0] block;
wire block_ready;

//update_cache variables
wire updated;

initial
    prev_mem_trace = 0;

assign reset = (prev_mem_trace==memory_trace) ? 0 : 1; 
assign mem_addr = {16'b0,memory_trace};
assign block_offset = mem_addr[block_offset_index-1:0];
assign index = mem_addr[set_index+block_offset_index-1:block_offset_index];
assign tag = mem_addr[31:set_index+block_offset_index];

find_data_and_update #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i1 (clk,reset,block_ready,tag,index,block_offset,block,cache_hit,cache_miss,updated,found_in_cache);
request_block #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i2 (clk,reset,found_in_cache,tag,index,block_offset,block,block_ready);
//update_cache #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i3 (clk,block_ready,tag,index,block,updated,cache_miss);

always @ (posedge clk)
    prev_mem_trace <= memory_trace;
endmodule
