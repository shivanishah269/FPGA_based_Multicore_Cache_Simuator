`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2020 22:12:00
// Design Name: 
// Module Name: lru
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


module lru(clk,index,start,found_in_cache,updated_cache,replace,way_index,replace_index,block_replace,update_lru);

parameter way = 4;
parameter block_size_byte = 16;
parameter cache_size_byte = 32*1024;
    
parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
parameter set = cache_size_byte/(block_size_byte*way); 
parameter set_index = $rtoi($ln(set)/$ln(2));

input clk,start,found_in_cache,updated_cache,replace;
input [set_index-1:0] index;
input [4:0] way_index;
output reg [4:0] replace_index;
output reg block_replace;
output reg update_lru;

parameter way_width = $rtoi($ln(way)/$ln(2)); 

reg state,temp_found_in_cache,temp_updated_cache,temp_replace;
reg [way_width-1:0]lru_count [0:set-1] [0:way-1];

integer i,j;

initial
begin
    state = 1'b0;
    block_replace = 0;
    replace_index = 0;
    update_lru = 0;
    for(i=0;i<set;i=i+1)
        for(j=0;j<way;j=j+1)
            lru_count[i][j] = j;
    temp_found_in_cache = 1'b0;
    temp_updated_cache = 1'b0;
    //temp_updated_cache_prefetch = 1'b0;
    temp_replace = 1'b0;            
end

always @ (posedge clk)
begin
    case (state)
    
        1'b0: begin
                i = 0;
                //update_lru = 1'b0;
                block_replace = 1'b0;                
                replace_index = 0;
                    
                if(start)
                begin
                    state = 1'b1;
                    if(found_in_cache)
                        temp_found_in_cache = 1'b1;
                    if(updated_cache)
                        temp_updated_cache = 1'b1;
                    //if(updated_cache_prefetch)
                        //temp_updated_cache_prefetch = 1'b1;    
                    if(replace)
                        temp_replace = 1'b1; 
                    
                end     
              end
              
        1'b1: begin
                if(update_lru)
                begin
                    state = 1'b0;
                    temp_found_in_cache = 1'b0;
                    temp_updated_cache = 1'b0;
                    //temp_updated_cache_prefetch = 1'b0;
                    temp_replace = 1'b0;
                    update_lru = 1'b0;
                end    
                else
                begin
                    //It is found in cache but need to update LRU table
                    if(temp_found_in_cache && !update_lru)
                    begin
                        if(i<way)
                        begin
                            if(lru_count[index][i] > lru_count[index][way_index-1])
                                lru_count[index][i] = lru_count[index][i] - 1;
                            
                            i = i + 1;               
                        end
                        if(i==way)
                        begin
                            lru_count[index][way_index-1] = way - 1;
                            update_lru = 1'b1;
                        end                  
                    end
                    
                    // special case of above case
                    // It is not in cache but there was empty block in cache so no need to replace
                    if(!temp_found_in_cache && (temp_updated_cache) && !update_lru)
                    begin
                        if(i<way)
                        begin
                            if(lru_count[index][i]==0)
                                lru_count[index][i] = way-1;
                            else
                                lru_count[index][i] = lru_count[index][i] - 1;
                            
                            i = i + 1;               
                        end
                        if(i==way)
                            update_lru = 1'b1;
                    end
                    
                    // It is not in cache and particular index is completely full
                    if(!temp_updated_cache && temp_replace && !update_lru)
                    begin
                        if(i<way)
                        begin
                            if(!lru_count[index][i])
                            begin
                                replace_index = i;
                                lru_count[index][i] = way-1;
                                i = i + 1;
                            end
                            else
                            begin
                                lru_count[index][i] = lru_count[index][i] - 1;     
                                i = i + 1;
                            end     
                        end
                        if(i==way)
                        begin
                            update_lru = 1'b1;
                            block_replace = 1'b1;
                        end            
                    end                     
                 end
              end 
    endcase    
end
endmodule