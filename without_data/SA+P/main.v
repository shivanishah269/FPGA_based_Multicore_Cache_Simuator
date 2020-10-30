`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2020 22:12:00
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


module main(clk,trace_ready,update_lru,mem_addr,cache_hit_count,cache_miss_count);

    input clk,trace_ready;
    input [31:0] mem_addr;
    
    output [31:0] cache_hit_count,cache_miss_count;
    output update_lru;
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

     // variables to divide address in tag, index and offset
    //wire [31:0] mem_addr;
    wire [31-set_index-block_offset_index:0] tag;
    wire [set_index-1:0] index;
    wire [block_offset_index-1:0] block_offset;
    
    // memory_trace variables
    //wire [15:0] memory_trace;
    //wire trace_ready;
    
    //find_data variables
    wire found_in_cache,found_in_prefetcher,done_cache,done_prefetch,block_replace,replace;
    //wire [15:0] cache_hit_count,cache_miss_count;
    //wire [4:0] hit_latency;
    wire [4:0] replace_way,way_index;
    
    //request_block variables
    //wire [(block_size_byte*8)-1:0] block_cache,block_prefetch;
    //wire block_ready_cache,block_ready_prefetch;
    //wire [4:0] miss_latency;
    
    //update_cache variables
    wire updated_cache;
    //wire updated_cache_prefetch;  
    
    //update lru
    //wire update_lru; 
    
    //next_line_prefetcher
    wire [31:0] prefetch_address;
    wire prefetch_miss,prefetch_hit;
    //wire [(block_size_byte*8)-1:0] prefetch_data; 
    
    /*
    ila_0 i5 (
	.clk(clk), // input wire clk
	.probe0(mem_addr), // input wire [31:0]  probe0  
	.probe1(cache_hit_count), // input wire [15:0]  probe1 
	.probe2(cache_miss_count) // input wire [15:0]  probe2
); 
*/
    //assign mem_addr = {16'b0,memory_trace};
    assign block_offset = mem_addr[block_offset_index-1:0];
    assign index = mem_addr[set_index+block_offset_index-1:block_offset_index];
    assign tag = mem_addr[31:set_index+block_offset_index];
    
    //memory_trace i1 (clk,update_lru,memory_trace,trace_ready);
      
    find_data_and_update #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i2 
    (clk,trace_ready,prefetch_hit,tag,index,block_offset,block_replace,replace_way,way_index,cache_hit_count,cache_miss_count,found_in_cache,found_in_prefetcher,updated_cache,done_cache,done_prefetch,replace);
    
    //request_block #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i3 
    //(clk,(!found_in_prefetcher&done_prefetch),prefetch_miss,trace_ready,tag,index,block_offset,prefetch_address,block_cache,block_prefetch,block_ready_cache,block_ready_prefetch,miss_latency); 
    
    next_line_prefetcher #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i4 
    (clk,mem_addr,(!found_in_cache&done_cache),prefetch_address,prefetch_hit,prefetch_miss);
    
    lru #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i5 
    (clk,index,found_in_cache|(!found_in_cache&(updated_cache)&!replace)|(!updated_cache&replace),found_in_cache,updated_cache,replace,way_index,replace_way,block_replace,update_lru);
endmodule