`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.03.2021 04:59:38
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


module main(clk,reset,trace_ready,mem_addr,updated,L1_hit_count,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16,ss1_index,ss1_updated,ss1_found_in_cache,ss1_hit_way);

    parameter L1_way = 4;
    parameter L1_block_size_byte = 16;
    parameter L1_cache_size_byte = 1*1024;
    
    parameter L2_way = 16;
    parameter L2_block_size_byte = 16;
    parameter L2_set_size = 64;
    
    parameter L1_block_offset_index = $rtoi($ln(L1_block_size_byte)/$ln(2));
    parameter L1_set = L1_cache_size_byte/(L1_block_size_byte*L1_way);
    parameter L1_set_index = $rtoi($ln(L1_set)/$ln(2));
    parameter L1_way_width = $rtoi($ln(L1_way)/$ln(2));
    
    parameter L2_block_offset_index = $rtoi($ln(L2_block_size_byte)/$ln(2));
    parameter L2_set_index = $rtoi($ln(L2_set_size)/$ln(2));
    parameter L2_way_width = $rtoi($ln(L2_way)/$ln(2));

    input clk,trace_ready,reset;
    input [31:0] mem_addr;
    
    output [19:0] L1_hit_count,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16;
    output updated;
    output ss1_found_in_cache,ss1_updated;
    output [L2_way_width:0] ss1_hit_way;
    output [L2_set_index-2:0] ss1_index;
    
    // variables to divide address in tag, index and offset for L1 cache
    wire [31-L1_set_index-L1_block_offset_index:0] L1_tag;
    wire [L1_set_index-1:0] L1_index;
    wire [L1_block_offset_index-1:0] L1_block_offset;
    
    // variables to divide address in tag, index and offset for L2 cache
    wire [31-L2_set_index-L2_block_offset_index:0] L2_tag;
    wire [L2_set_index-1:0] L2_index;
    wire [L2_block_offset_index-1:0] L2_block_offset;
    
    //L1 cache 
    wire L1_done,L1_found_in_cache,L1_updated;
    
    //L2 cache
    wire L2_done,L2_found_in_cache,L2_updated ;
    //wire [31:0] back_invalidation_data;
    wire [L2_way_width:0] L2_hit_way;
    
    //Subset cache1
    //wire ss1_found_in_cache,ss1_updated;
    //wire [L2_way_width:0] ss1_hit_way;
    
    //Subset cache2
    wire ss2_found_in_cache,ss2_updated;
    wire [L2_way_width:0] ss2_hit_way;
    //wire [L2_set_index-2:0] ss1_index;
    
    //prefetcher
    wire prefetch_hit,prefetch_done;
    

    assign L1_block_offset = mem_addr[L1_block_offset_index-1:0];
    assign L1_index = mem_addr[L1_set_index+L1_block_offset_index-1:L1_block_offset_index];
    assign L1_tag = mem_addr[31:L1_set_index+L1_block_offset_index];
    
    assign L2_block_offset = mem_addr[L2_block_offset_index-1:0];
    assign L2_index = mem_addr[L2_set_index+L2_block_offset_index-1:L2_block_offset_index];
    assign L2_tag = mem_addr[31:L2_set_index+L2_block_offset_index]; 
    
    assign ss1_index = L2_index[L2_set_index-2:0];
    assign updated = !prefetch_hit&&ss1_updated ? 1'b1 : L1_updated&&(prefetch_hit||L1_found_in_cache) ? 1'b1 :  1'b0;      
    
    L1_cache #(.way(L1_way),.block_size_byte(L1_block_size_byte),.cache_size_byte(L1_cache_size_byte)) i1  (clk,reset,L1_tag,L1_index,L1_block_offset,trace_ready,prefetch_hit,L2_found_in_cache,L1_hit_count,L1_found_in_cache,L1_updated,L1_done,prefetch_done);
    L2_cache #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size)) i2 (clk,reset,L2_tag,L2_index,L2_block_offset,(prefetch_done && !prefetch_hit),L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_found_in_cache,L2_hit_way,L2_done,L2_updated);
    L2_cache_subset #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size/2)) i3 (clk,reset,L2_index,L2_updated,L2_found_in_cache,L2_hit_way,ss1_found_in_cache,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,ss1_hit_way,ss1_updated);
    L2_cache_subset #(.way(L2_way),.block_size_byte(L2_block_size_byte),.set_size(L2_set_size/4)) i4 (clk,reset,ss1_index,ss1_updated,ss1_found_in_cache,ss1_hit_way,ss2_found_in_cache,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16,ss2_hit_way,ss2_updated);
    prefetcher #(.way(L1_way),.block_size_byte(L1_block_size_byte),.cache_size_byte(L1_cache_size_byte)) i5(clk,mem_addr,(L1_done && !L1_found_in_cache),prefetch_hit);
    
endmodule