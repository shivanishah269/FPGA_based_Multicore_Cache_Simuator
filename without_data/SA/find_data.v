`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.07.2020 19:24:42
// Design Name: 
// Module Name: find_data
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


module find_data_and_update (clk,tag,index,block_offset,find_start,block_replace,replace_way,way_index,cache_hit_count,cache_miss_count,found_in_cache,updated,done,replace);
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

    
    input clk,find_start,block_replace;
    //input update_start;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    //input [(block_size_byte*8)-1:0] block;
    input [4:0] replace_way;
    output reg found_in_cache,done;
    output reg [31:0] cache_hit_count,cache_miss_count;
    //output reg [4:0] hit_latency,
    output reg [4:0] way_index;
    output reg updated,replace;
    
    reg find_state,update_state;
    reg [29:0] cache [0:set-1][0:way-1];
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;
        cache_miss_count = 0;
        //hit_latency = 0;
        done = 0;
        find_state = 0;
        update_state = 0;
        updated = 0;
        way_index = 0;
        replace = 0;
        for (i=0;i<set;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        case (find_state)
            1'b0: begin
                    //found_in_cache = 1'b0;
                    //done = 1'b0;
                    if(find_start)
                    begin
                        find_state = 1'b1;
                        //hit_latency = 0;
                        way_index = 0;
                    end    
                  end
            1'b1: begin
                    if (done)
                    begin
                        found_in_cache = 1'b0;
                        done = 1'b0;
                        find_state = 1'b0;
                    end    
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
                                    done = 1'b1;
                                end    
                            end
                            way_index = way_index + 1'b1;                                                                             
                        end
                        if (way_index==way&&!found_in_cache)
                        begin
                            found_in_cache = 1'b0;
                            cache_miss_count = cache_miss_count + 1'b1;
                            done = 1'b1;
                        end                        
                    end  
                  end
        endcase
        
        case (update_state)
            1'b0: begin
                    //updated = 1'b0;
                    //replace = 1'b0;
                    if (done && !found_in_cache)
                    begin
                        update_state = 1'b1;
                        way_index = 0;
                    end
                  end
            1'b1: begin
                    if(updated)
                    begin
                        update_state = 1'b0;
                        replace = 1'b0;
                        updated = 1'b0;
                    end
                    else
                    begin
                        temp_tag = tag;
                        //temp_data = block; // if data required uncomment this line
                        if (way_index<=way-1)
                        begin
                            if(!cache[index][way_index][29])
                            begin
                                //cache[index][way_index] = {1'b1,temp_tag,temp_data}; // with data
                                cache[index][way_index] = {1'b1,temp_tag}; // without data
                                updated = 1'b1;
                            end
                            way_index = way_index + 1'b1;
                        end
                        
                        if(way_index==way&&!updated)
                        begin
                            replace = 1'b1;
                            way_index = way_index + 1'b1;
                        end  
                        if(block_replace)
                        begin
                            //cache[index][replace_way] = {1'b1,temp_tag,temp_data};// with data
                            cache[index][replace_way] = {1'b1,temp_tag}; // without data
                            updated = 1'b1;
                        end   
                       
                    end  
                  end
        endcase     
    end        
endmodule

