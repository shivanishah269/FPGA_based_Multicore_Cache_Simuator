`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2020 12:42:46
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


module main(clk,trace_ready,mem_addr,updated,cache_hit_count,cache_miss_count);

    input clk,trace_ready;
    input [31:0] mem_addr;
    
    output [19:0] cache_hit_count,cache_miss_count;
    output updated;
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

     // variables to divide address in tag, index and offset
    wire [31-set_index-block_offset_index:0] tag;
    wire [set_index-1:0] index;
    wire [block_offset_index-1:0] block_offset;
    
    //find_data variables
    wire found_in_cache,done;
    
    //next_line_prefetcher variables
    wire prefetch_hit,prefetch_miss;
  
    assign block_offset = mem_addr[block_offset_index-1:0];
    assign index = mem_addr[set_index+block_offset_index-1:block_offset_index];
    assign tag = mem_addr[31:set_index+block_offset_index];
  
    cache #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i1 (clk,tag,index,block_offset,trace_ready,prefetch_hit,cache_hit_count,cache_miss_count,found_in_cache,updated,done);
    next_line_prefetcher #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i2 (clk,mem_addr,(done && !found_in_cache),prefetch_hit,prefetch_miss);
    
endmodule