`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.09.2020 15:51:51
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


module find_data_and_update (clk,start_cache,prefetch_hit,update_cache_mem,tag,index,block_offset,block_cache,prefetch_data,cache_hit_count,cache_miss_count,hit_latency,found_in_cache,found_in_prefetcher,updated_cache_mem,updated_cache_prefetch,done_cache,done_prefetch);
    
    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    
    input clk,start_cache,prefetch_hit,update_cache_mem;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    input [(block_size_byte*8)-1:0] block_cache,prefetch_data;
    output reg found_in_cache,done_cache,done_prefetch,found_in_prefetcher;
    output reg [15:0] cache_hit_count,cache_miss_count;
    output reg [4:0] hit_latency;
    output reg updated_cache_mem,updated_cache_prefetch;
    
    reg [1:0]find_state_cache;
    reg update_state_mem,update_state_prefetcher;
    reg [157:0] cache [0:2047];
    
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    reg flag;
    
    integer i;
    
    initial
    begin
        found_in_cache = 0;
        found_in_prefetcher = 0;
        cache_hit_count = 0;
        cache_miss_count = 0;
        hit_latency = 0;
        done_cache = 0;
        done_prefetch = 0;
        find_state_cache = 0;
        update_state_mem = 0;
        update_state_prefetcher = 0;
        updated_cache_mem = 0;
        updated_cache_prefetch = 0;
        flag = 0;
        for (i=0;i<2048;i=i+1)
            cache[i] = 0;
    end
    
    always @ (posedge clk)
    begin
        // find in cache
        case (find_state_cache)
            2'b00: begin
                    found_in_cache = 1'b0;
                    found_in_prefetcher = 1'b0;
                    done_cache = 1'b0;
                    done_prefetch = 1'b0;
                    flag = 1'b0;                    
                    if(start_cache)
                    begin
                        find_state_cache = 1'b1;
                        hit_latency = 0;
                    end    
                  end
            2'b01: begin
                    if (done_cache&!found_in_cache)
                        find_state_cache= 2'b10;
                    else if(done_cache&found_in_cache)
                        find_state_cache = 2'b00;    
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
                            else // trigger prefetcher block
                            begin                           
                                found_in_cache = 1'b0;
                                //cache_miss_count = cache_miss_count + 1'b1;
                            end 
                        end
                        else // trigger prefetcher block
                        begin
                            found_in_cache = 1'b0;
                            //cache_miss_count = cache_miss_count + 1'b1;
                        end
                        done_cache = 1'b1;
                    end
                  end  
            2'b10: begin
                       if(done_prefetch)
                          find_state_cache= 2'b00;
                       else
                       begin
                          if(!flag)
                              flag = 1'b1;
                          else
                          begin
                              if(prefetch_hit&flag)                        
                              begin
                                  flag = 1'b0;
                                  cache_hit_count = cache_hit_count + 1'b1;
                                  hit_latency = hit_latency + 2;
                                  found_in_prefetcher = 1'b1;   
                              end
                              else
                              begin
                                  found_in_prefetcher = 1'b0; 
                                  cache_miss_count = cache_miss_count + 1'b1;
                              end
                              done_prefetch = 1'b1;
                          end            
                       end
            
                   end 
                              
                  
        endcase


        
        // update cache from memory
        case (update_state_mem)
            1'b0: begin
                    updated_cache_mem = 1'b0;
                    if (update_cache_mem) // block_ready_cache
                        update_state_mem = 1'b1;
                  end
            1'b1: begin
                    if(updated_cache_mem)
                        update_state_mem = 1'b0;
                    else
                    begin
                        temp_tag = tag;
                        temp_data = block_cache;
                        cache[index] = {1'b1,temp_tag,temp_data};                             
                        updated_cache_mem = 1'b1;
                        //request_block.miss_latency = request_block.miss_latency + 1'b1;
                    end  
                  end
        endcase
        
        // update cache from prefetcher
        case (update_state_prefetcher)
            1'b0: begin
                    updated_cache_prefetch = 1'b0;
                    if (prefetch_hit) // some signal from prefetcher
                        update_state_prefetcher = 1'b1;
                  end
            1'b1: begin
                    if(updated_cache_prefetch)
                        update_state_prefetcher = 1'b0;
                    else
                    begin
                        temp_tag = tag;
                        temp_data = prefetch_data;
                        cache[index] = {1'b1,temp_tag,temp_data};                             
                        updated_cache_prefetch = 1'b1;
                        //request_block.miss_latency = request_block.miss_latency + 1'b1;
                    end  
                  end
        endcase     
    end        
endmodule
