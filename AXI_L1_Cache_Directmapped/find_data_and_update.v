`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2020 10:55:16
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


module find_data_and_update (clk,find_start,update_start,tag,index,block_offset,block,cache_hit_count,cache_miss_count,hit_latency,found_in_cache,updated,done);
    
    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    
    input clk,find_start,update_start;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    input [(block_size_byte*8)-1:0] block;
    output reg found_in_cache,done;
    output reg [15:0] cache_hit_count,cache_miss_count;
    output reg [4:0] hit_latency;
    output reg updated;
    
    reg find_state,update_state;
    reg [157:0] cache [0:2047];
    
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    
    integer i;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;
        cache_miss_count = 0;
        hit_latency = 0;
        done = 0;
        find_state = 0;
        update_state = 0;
        updated = 0;
        for (i=0;i<2048;i=i+1)
            cache[i] = 0;
    end
    
    always @ (posedge clk)
    begin
        case (find_state)
            1'b0: begin
                    found_in_cache = 1'b0;
                    done = 1'b0;
                    if(find_start)
                    begin
                        find_state = 1'b1;
                        hit_latency = 0;
                    end    
                  end
            1'b1: begin
                    if (done)
                        find_state = 1'b0;
                    else
                    begin
                        if(cache[index][157])
                        begin
                            if(cache[index][156:128]==tag)
                            begin
                                found_in_cache = 1'b1;
                                cache_hit_count = cache_hit_count + 1'b1;
                                hit_latency = hit_latency + 1'b1;
                            end
                            else
                            begin
                                found_in_cache = 1'b0;
                                cache_miss_count = cache_miss_count + 1'b1;
                            end 
                        end
                        else
                        begin
                            found_in_cache = 1'b0;
                            cache_miss_count = cache_miss_count + 1'b1;
                        end
                        done = 1'b1;
                    end  
                  end
        endcase
        
        case (update_state)
            1'b0: begin
                    updated = 1'b0;
                    if (update_start)
                        update_state = 1'b1;
                  end
            1'b1: begin
                    if(updated)
                        update_state = 1'b0;
                    else
                    begin
                        temp_tag = tag;
                        temp_data = block; 
                        cache[index] = {1'b1,temp_tag,temp_data};
                        updated = 1'b1;
                        //request_block.miss_latency = request_block.miss_latency + 1'b1;
                    end  
                  end
        endcase     
    end        
endmodule

