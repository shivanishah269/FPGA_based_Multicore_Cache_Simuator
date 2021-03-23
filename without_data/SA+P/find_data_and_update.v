`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2020 22:12:00
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


module find_data_and_update (clk,start_cache,prefetch_hit,tag,index,block_offset,block_replace,replace_way,way_index,cache_hit_count,cache_miss_count,found_in_cache,found_in_prefetcher,updated_cache,done_cache,done_prefetch,replace);
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

    
    input clk,start_cache,prefetch_hit,block_replace;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    //input [(block_size_byte*8)-1:0] block_cache,prefetch_data;
    input [4:0] replace_way;
    output reg found_in_cache,done_cache,done_prefetch,found_in_prefetcher;
    output reg [31:0] cache_hit_count,cache_miss_count;
    //output reg [4:0] hit_latency;
    output reg [4:0] way_index;
    output reg updated_cache,replace;
    
    reg [1:0]find_state_cache;
    reg update_state_mem,update_state_prefetcher;
    
    reg [157:0] cache [0:set-1][0:way-1];
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    reg flag;
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;
        cache_miss_count = 0;
        //hit_latency = 0;
        done_cache = 0;
        done_prefetch = 0;
        find_state_cache = 0;
        update_state_mem = 0;
        update_state_prefetcher = 0;
        updated_cache = 0;
        //updated_cache_prefetch = 0;
        flag = 0;
        way_index = 0;
        replace = 0;
        for (i=0;i<set;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        case (find_state_cache)
            2'b00: begin
                    found_in_cache = 1'b0;
                    found_in_prefetcher = 1'b0;
                    done_cache = 1'b0;
                    //done_prefetch = 1'b0;
                    flag = 1'b0;
                    if(start_cache)
                    begin
                        find_state_cache = 1'b1;
                        //hit_latency = 0;
                        way_index = 0;
                    end    
                  end
            2'b01: begin
                    if (done_cache&!found_in_cache)
                        find_state_cache= 2'b10;
                    else if(done_cache&found_in_cache)
                        find_state_cache = 2'b00;    
                    else
                    begin
                        if(way_index<=way-1) 
                        begin
                            if(cache[index][way_index][29])
                            begin
                                if(cache[index][way_index][28:0]==tag)
                                begin
                                    found_in_cache = 1'b1;
                                    cache_hit_count = cache_hit_count + 1'b1;
                                    //hit_latency = hit_latency + 1'b1;
                                    done_cache = 1'b1;
                                end    
                            end
                            way_index = way_index + 1'b1;                                                                             
                        end
                        if (way_index==way&&!found_in_cache)
                        begin
                            found_in_cache = 1'b0;
                            //cache_miss_count = cache_miss_count + 1'b1;
                            done_cache = 1'b1;
                        end                        
                    end  
                  end
            
            2'b10: begin
                       if(done_prefetch)
                       begin
                          find_state_cache= 2'b00;
                          done_prefetch = 1'b0;
                       end   
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
                                  //hit_latency = hit_latency + 2;
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
                
        // update cache
        case (update_state_mem)
            1'b0: begin
                    //updated_cache_mem = 1'b0;
                    if (done_prefetch) // block_ready_cache
                        update_state_mem = 1'b1;
                  end
            1'b1: begin
                    if(updated_cache)
                    begin
                        updated_cache = 1'b0;
                        replace = 1'b0;
                        update_state_mem = 1'b0;
                    end    
                    else
                    begin
                        temp_tag = tag;
                        //temp_data = block_cache;
                        if (way_index<=way-1)
                        begin
                            if(!cache[index][way_index][29])
                            begin
                                //cache[index][way_index] = {1'b1,temp_tag,temp_data}; // with data
                                cache[index][way_index] = {1'b1,temp_tag}; // without data
                                updated_cache = 1'b1;
                            end
                            way_index = way_index + 1'b1;
                        end
                        
                        if(way_index==way&&!updated_cache)
                        begin
                            replace = 1'b1;
                            way_index = way_index + 1'b1;
                        end  
                        if(block_replace)
                        begin
                            //cache[index][replace_way] = {1'b1,temp_tag,temp_data};// with data
                            cache[index][replace_way] = {1'b1,temp_tag}; // without data
                            updated_cache = 1'b1;
                        end
                    end  
                  end
        endcase
        /*
        // update cache from prefetcher
        case (update_state_prefetcher)
            1'b0: begin
                    //updated_cache_prefetch = 1'b0;
                    if (prefetch_hit) // some signal from prefetcher
                        update_state_prefetcher = 1'b1;
                  end
            1'b1: begin
                    if(updated_cache_prefetch)
                    begin
                        update_state_prefetcher = 1'b0;
                        updated_cache_prefetch = 1'b0;
                        replace = 1'b0;
                    end
                    else
                    begin
                        temp_tag = tag;
                        temp_data = prefetch_data;
                        if (way_index<=way-1)
                        begin
                            if(!cache[index][way_index][157])
                            begin
                                cache[index][way_index] = {1'b1,temp_tag,temp_data};
                                updated_cache_prefetch = 1'b1;
                            end
                            way_index = way_index + 1'b1;
                        end
                        
                        if(way_index==way&&!updated_cache_prefetch)
                        begin
                            replace = 1'b1;
                            way_index = way_index + 1'b1;
                        end  
                        if(block_replace)
                        begin
                            cache[index][replace_way] = {1'b1,temp_tag,temp_data};
                            updated_cache_prefetch = 1'b1;
                        end
                    end  
                  end
        endcase 
        */    
    end        
endmodule