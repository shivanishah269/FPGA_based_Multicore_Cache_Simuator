`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.03.2021 04:59:38
// Design Name: 
// Module Name: NLP_Prefetcher
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


module prefetcher (clk,address,cache_miss,prefetch_hit);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 1*1024;
    parameter way_width = $rtoi($ln(way)/$ln(2));
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));  //2
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
     
    parameter prefetch_width = 32-block_offset_index  + 1; // without data (tag+index+valid) 
    
    input clk,cache_miss;
    input [31:0]address;
    output reg prefetch_hit;
        
endmodule