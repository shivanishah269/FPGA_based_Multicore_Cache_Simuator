`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2020 12:25:07
// Design Name: 
// Module Name: find_data_and_update
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


module find_data_and_update(clk2,reset,control,tag,index,block_offset,block,cache_hit,cache_miss,updated,found_in_cache);

    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    
    input clk2,control,reset;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    input [(block_size_byte*8)-1:0] block;
    output reg updated,found_in_cache;
    output reg [15:0] cache_hit,cache_miss;
    
    reg done;
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    reg [157:0] cache [0:2047];
    
    integer i;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit = 0;
        cache_miss = 0;
        updated = 0;
        done = 0;
        for (i=0;i<2048;i=i+1)
            cache[i] = 0;
    end
    
    always @ (posedge clk2)
    begin
        if(reset)
        begin
            found_in_cache = 1'b0;
            updated = 1'b0;
            done = 0;
        end
        else
        begin
            if(!done)
            begin
                if(cache[index][157])
                begin
                    if(cache[index][156:128]==tag)
                    begin
                        found_in_cache = 1'b1;
                        cache_hit = cache_hit + 1'b1;
                    end
                end
                else
                    found_in_cache = 1'b0;
                done = 1'b1;                
            end
        end
        
        if(control)
        begin
           temp_tag = tag;
           temp_data = block; 
           cache[index] = {1'b1,temp_tag,temp_data};
           updated = 1'b1;
           cache_miss = cache_miss + 1;
        end
    end
endmodule
