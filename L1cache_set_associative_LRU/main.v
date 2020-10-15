`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2020 12:25:07
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


module main(clk);

    input clk;
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 1*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

     // variables to divide address in tag, index and offset
    wire [31:0] mem_addr;
    wire [31-set_index-block_offset_index:0] tag;
    wire [set_index-1:0] index;
    wire [block_offset_index-1:0] block_offset;
    
    // memory_trace variables
    wire [15:0] memory_trace;
    wire trace_ready;
    
    //find_data variables
    wire found_in_cache,done,block_replace,replace;
    wire [15:0] cache_hit_count,cache_miss_count;
    wire [4:0] hit_latency,replace_way,way_index;
    
    //request_block variables
    wire [(block_size_byte*8)-1:0] block;
    wire block_ready;
    wire [4:0] miss_latency;
    
    //update_cache variables
    wire updated;  
    
    //update lru
    wire update_lru;  
    
    
    ila_0 i5 (
	.clk(clk), // input wire clk
	.probe0(mem_addr), // input wire [31:0]  probe0  
	.probe1(cache_hit_count), // input wire [15:0]  probe1 
	.probe2(cache_miss_count) // input wire [15:0]  probe2
); 

    assign mem_addr = {16'b0,memory_trace};
    assign block_offset = mem_addr[block_offset_index-1:0];
    assign index = mem_addr[set_index+block_offset_index-1:block_offset_index];
    assign tag = mem_addr[31:set_index+block_offset_index];
    
    memory_trace i1 (clk,update_lru,memory_trace,trace_ready);  
    find_data_and_update #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i2 (clk,tag,index,block_offset,trace_ready,block_ready,block_replace,block,replace_way,way_index,cache_hit_count,cache_miss_count,hit_latency,found_in_cache,updated,done,replace);
    request_block #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i3 (clk,tag,index,block_offset,(!found_in_cache&done),trace_ready,block,block_ready,miss_latency);
    lru #(.way(way),.block_size_byte(block_size_byte),.cache_size_byte(cache_size_byte)) i4 (clk,index,found_in_cache|(!found_in_cache&updated&!replace)|(!updated&replace),found_in_cache,updated,replace,way_index,replace_way,block_replace,update_lru);
    
    
endmodule
