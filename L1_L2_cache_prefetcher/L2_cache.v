`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2021 13:36:49
// Design Name: 
// Module Name: L2_cache
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


module L2_cache(clk,reset,tag,index,block_offset,find_start,cache_hit_count4,cache_hit_count8,cache_hit_count16,found_in_cache,hit_way,done,updated,back_invalidation,back_invalidation_data);

    parameter way = 16;
    parameter block_size_byte = 16;
    parameter set_size = 512;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2)); 
    parameter set_index = $rtoi($ln(set_size)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    parameter cache_line_width = 32-set_index-block_offset_index+1; 
    
    input clk,find_start,reset;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg found_in_cache;
    // this needs to get parameterized based on number of max associativity        
    output reg [19:0] cache_hit_count4;    
    output reg [19:0] cache_hit_count8;
    output reg [19:0] cache_hit_count16;
    output reg [way_width:0] hit_way;
    //reg [19:0] cache_miss_count;
    output reg updated,done;
    output reg back_invalidation;
    output reg [31:0] back_invalidation_data;
    
    reg [1:0]find_state;
    reg [way_width:0] way_index;    
    reg [cache_line_width-1:0] cache [0:set_size-1][0:way-1];
    reg [cache_line_width-1:0] temp_content;
    //reg [19:0] hit_count [way-1:0];
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;        
        cache_hit_count4 = 0;        
        cache_hit_count8 = 0;
        cache_hit_count16 = 0;
        //cache_miss_count = 0;        
        find_state = 0;
        updated = 0;
        back_invalidation = 0;
        back_invalidation_data = 0;
        //for (i=0;i<way;i=i+1)
          //  hit_count[i] = 0;
        for (i=0;i<set_size;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;        
            cache_hit_count4 = 0;        
            cache_hit_count8 = 0;
            cache_hit_count16 = 0;
            //cache_miss_count = 0;        
            find_state = 0;
            updated = 0;
            back_invalidation = 0;
            back_invalidation_data = 0;
            //for (i=0;i<way;i=i+1)
              //  hit_count[i] = 0;
            for (i=0;i<set_size;i=i+1)
                for (j=0;j<way;j=j+1)
                    cache[i][j] = 0;    
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                        found_in_cache = 1'b0;                             
                        if(find_start)
                        begin
                            find_state = 2'b01;                        
                            done = 1'b0;
                        end        
                      end
                      // Find cache state (to check if particular memory address data is present in cache or not)
                      
                2'b01: begin
                  
                        if (done)
                        begin
                            find_state = 2'b10;
                            back_invalidation = 1'b0;                        
                        end        
                        else
                        begin
                            for (way_index=0;way_index<way;way_index=way_index+1'b1)
                            begin
                                if(cache[index][way_index][cache_line_width-1]) // valid bit
                                begin
                                    if(cache[index][way_index][cache_line_width-2:0]==tag) // tag comparison
                                    begin
                                        found_in_cache = 1'b1;                                    
                                        hit_way = way_index;                                    
                                        temp_content = cache[index][way_index];                                    
                                    end
                               end 
                               // increment the counters with respect to their associativity
                               //if(found_in_cache)
                                 //   hit_count[way_index] = hit_count[way_index] + 1;                                                                                          
                            end                        
                            /*                             
                            if (found_in_cache)
                            begin                        
                                cache_hit_count4 = hit_count[3];                            
                                cache_hit_count8 = hit_count[7];
                                cache_hit_count16 = hit_count[15];
                                done = 1'b1;
                            end*/  
                            if (found_in_cache)
                            begin
                                if (hit_way>=0 && hit_way<4)
                                begin
                                    cache_hit_count4 = cache_hit_count4 + 1;
                                    cache_hit_count8 = cache_hit_count8 + 1;
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                else if (hit_way>=4 && hit_way<8)
                                begin
                                    cache_hit_count8 = cache_hit_count8 + 1;
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                else if (hit_way>=8 && hit_way<16)
                                begin                                    
                                    cache_hit_count16 = cache_hit_count16 + 1;
                                end
                                done = 1'b1;
                                way_index = hit_way;                                                                                      
                            end  
                            else                                                                
                            begin
                                if(cache[index][way-1][cache_line_width-1]) // checking if that particular set is full or not                            
                                begin
                                    back_invalidation = 1'b1;
                                    back_invalidation_data = {cache[index][way-1],index,block_offset};
                                end                                
                                //cache_miss_count = cache_miss_count + 1'b1;
                                hit_way = way;
                                done = 1'b1;
                            end                                                  
                        end 
                       end
                      
                       // Updation of cache according LRU shift register policy
                2'b10: begin                
                        if(updated)
                        begin
                            find_state = 2'b00;
                            updated = 1'b0;
                        end
                        else
                        begin                            
                            if(found_in_cache) // hit
                            begin 
                                   if(way_index != 0)
                                    begin
                                        cache[index][way_index] = cache[index][way_index-1];
                                        way_index = way_index - 1;
                                    end
                                    else
                                    begin            
                                        cache[index][0] = temp_content;
                                        updated = 1'b1;
                                    end                                                                       
                            end    
                            else // miss
                            begin                                                                                          
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                            
                                  cache[index][way_index+1] = cache[index][way_index];                                    
    
                                cache[index][1] = cache[index][0];
                                cache[index][0] = {1'b1,tag};
                                updated = 1'b1;             
                            end
                        end                           
                       end 
                        
            endcase
         end       
    end  
endmodule