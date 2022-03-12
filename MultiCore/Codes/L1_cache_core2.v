`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.08.2021 11:29:30
// Design Name: 
// Module Name: L1_cache_core2
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


module L1_cache_core2(clk,reset,tag,index,block_offset,find_start,ins_type,bus_signals,other_copy,prefetch_hit,cache_hit_count,found_in_cache,updated,done_L1,done_prefetch,copy_core2);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    parameter cache_line_width = 1+1+3+32-set_index-block_offset_index;
    
    input clk,find_start,prefetch_hit,reset,ins_type;
    input [4:0] bus_signals;
    input other_copy;
    input [31-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg found_in_cache;
    output reg [19:0] cache_hit_count;
    output reg updated,done_L1,done_prefetch;
    output reg copy_core2;
    
    reg [1:0]find_state;
    reg [1:0]flag;
    reg bi_flag;
    reg [way_width:0] way_index;
    reg [way_width-1:0] hit_way;
    reg [cache_line_width-1:0] cache [0:set-1][0:way-1]; // {valid,dirty,MESI protocol bits,tag}
    reg [cache_line_width-1:0] temp_content;    
    
    integer i,j;
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count = 0;
        find_state = 0;
        flag = 0;
        bi_flag = 0;
        updated = 0;
        done_prefetch = 0;
        copy_core2 = 0;
        for (i=0;i<set;i=i+1)
            for (j=0;j<way;j=j+1)
                cache[i][j] = 0;
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;
            cache_hit_count = 0;            
            find_state = 0;
            flag = 0;
            bi_flag = 0;
            updated = 0;
            done_prefetch = 0;
            copy_core2 = 0;            
            for (i=0;i<set;i=i+1)
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
                            copy_core2 = 1'b0;                
                            find_state = 2'b01;                        
                            done_L1 = 1'b0;
                        end        
                      end
                      
                2'b01: begin
                  
                        if (done_L1 && !found_in_cache && bus_signals[4:3] == 2)
                        begin
                            find_state = 2'b10;
                            done_L1 = 1'b0;
                        end
                        else if (done_L1 && !found_in_cache)
                        begin
                            find_state = 2'b11;
                            done_L1 = 1'b0;
                        end    
                        else if (done_L1 && found_in_cache)
                        begin
                            find_state = 2'b11;
                            done_L1 = 1'b0;
                            if (bus_signals[4:3] != 2)
                                copy_core2 = 1'b1;
                        end    
                        else
                        begin
                            for (way_index=0;way_index<way;way_index=way_index+1'b1)
                            begin
                                if(cache[index][way_index][cache_line_width-1]) // valid bit
                                begin
                                    if(cache[index][way_index][cache_line_width-6:0]==tag) // tag comparison
                                    begin
                                        found_in_cache = 1'b1;                                    
                                        hit_way = way_index;
                                        //if (!cache[index][way_index][cache_line_width-2] && ins_type) // check if there was load prior to store for same address then change dirty bit to 1
                                          //   cache[index][way_index][cache_line_width-2] = 1'b1;                                    
                                        temp_content = cache[index][way_index];
                                        if (bus_signals[4:3] == 2)
                                            cache_hit_count = cache_hit_count + 1'b1;
                                        done_L1 = 1'b1;                                    
                                    end
                               end                                                                                                                                                                                                                                                                                                                                                                                                                                
                            end                                               
                            if (way_index==way&&!found_in_cache)
                            begin                                     
                                    found_in_cache = 1'b0;                                
                                    done_L1 = 1'b1;
                            end                                                  
                        end 
                       end
    
                2'b10: begin
                        if(done_prefetch)
                        begin
                            find_state= 2'b11;
                            done_prefetch = 1'b0;
                            flag = 1'b0;
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
                                end                                                              
                                done_prefetch = 1'b1;
                            end            
                        end
                       end                                                        
                       
                2'b11: begin                
                        if(updated)
                        begin
                            find_state = 2'b00;
                            updated = 1'b0;
                        end
                        
                        else
                        begin
                            if(bus_signals[4:3] == 2)
                            begin
                                if(found_in_cache) // hit
                                begin  
                                    if(hit_way != 0)
                                        begin
                                            cache[index][hit_way] = cache[index][hit_way-1];
                                            hit_way = hit_way - 1;
                                        end
                                        else
                                        begin            
                                            cache[index][0] = temp_content;
                                            if (ins_type)  // Write hit - update MESI state to M along with dirty bit else not required
                                                cache[index][0][cache_line_width-2:cache_line_width-5] = 4'b1011;
                                            updated = 1'b1;
                                        end                                    
                                end 
                                
                                else // miss
                                begin
                                    for(way_index=way-2;way_index>0;way_index=way_index-1)                            
                                        cache[index][way_index+1] = cache[index][way_index];                                    
            
                                    cache[index][1] = cache[index][0];
                                    if ({ins_type,other_copy} == 2'b01) // read miss and present in other core
                                        cache[index][0] = {1'b1,1'b0,3'b010,tag};
                                    else if ({ins_type,other_copy} == 2'b00) // read miss and not present in other core
                                        cache[index][0] = {1'b1,1'b0,3'b001,tag};                                                                                                        
                                    else if (ins_type)  // Write miss
                                        cache[index][0] = {1'b1,1'b1,3'b011,tag};                                      
                                    updated = 1'b1;                                                  
                                end                                                                                                                                                                                                              
                                
                            end
                            else
                            begin
                                if (bus_signals[2:0] == 3'b100) // BusRd
                                begin
                                    if (cache[index][hit_way][cache_line_width-3:cache_line_width-5] == 3'b011) // Change M to S & dirty bit to 0
                                        cache[index][hit_way][cache_line_width-2:cache_line_width-5] = 4'b0010;
                                    else if (cache[index][hit_way][cache_line_width-3:cache_line_width-5] == 3'b001) // Change E to S
                                        cache[index][hit_way][cache_line_width-3:cache_line_width-5] = 3'b010;        
                                end
                                else if ((bus_signals[2:0] == 3'b010) || (bus_signals[2:0] == 3'b001)) // BusRdX or BusUpgr
                                    cache[index][hit_way][cache_line_width-1:cache_line_width-5] = 5'b00000;
                                
                                updated = 1'b1;                                                            
                            end
                         end                                                   
                       end                     
            endcase
         end       
    end   
    
endmodule