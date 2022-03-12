`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.08.2021 11:29:30
// Design Name: 
// Module Name: L2_cache_subset
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


module L2_cache_subset(clk,reset,msb_index,find_start,ins_type,L2_found_in_cache,hit_way,found_in_cache,cache_hit_count4,cache_hit_count8,cache_hit_count16,hit_source,updated);

    parameter way = 16;
    parameter block_size_byte = 16;
    parameter set_size = 512;   
    parameter set_index = $rtoi($ln(set_size)/$ln(2));
    parameter way_width = $rtoi($ln(way)/$ln(2));
    
    
    input clk,find_start,reset,L2_found_in_cache,ins_type;
    input [way_width:0] hit_way;
    input [set_index:0] msb_index;
    output reg found_in_cache;
    // this needs to get parameterized based on number of max associativity
    output reg [19:0] cache_hit_count4;
    output reg [19:0] cache_hit_count8;
    output reg [19:0] cache_hit_count16;
    output reg updated;
    output reg [way_width:0] hit_source;
    
    reg msb_indexbit,msb_update,mask_update;
    reg [set_index-1:0] index;        
    reg [way_width:0] way_index; 
      
    reg mask0 [0:set_size-1][0:way-1];
    reg mask1 [0:set_size-1][0:way-1];
    reg [2:0] source [0:set_size-1][0:way-1]; // {valid,dirty,source}
    reg [1:0] temp_data;
    reg temp_source;
    reg [way_width:0] count;    
    
    reg [1:0]find_state;
    reg done;    
    
    integer i,j;
    
    
    initial
    begin
        found_in_cache = 0;
        cache_hit_count4 = 0;        
        cache_hit_count8 = 0;
        cache_hit_count16 = 0;              
        find_state = 0;
        temp_data = 0;   
        msb_update = 0;  
        mask_update = 0;   
        for (i=0;i<set_size;i=i+1)
        begin
            for (j=0;j<way;j=j+1)
            begin
                source[i][j] = 0;
                mask0[i][j] = 0;
                mask1[i][j] = 0;
            end
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset)
        begin
            found_in_cache = 0;
            cache_hit_count4 = 0;        
            cache_hit_count8 = 0;
            cache_hit_count16 = 0;                    
            find_state = 0;
            temp_data = 0;            
            for (i=0;i<set_size;i=i+1)
            begin
                for (j=0;j<way;j=j+1)
                begin
                    source[i][j] = 0;
                    mask0[i][j] = 0;
                    mask1[i][j] = 0;
                end
            end
        end
        else
        begin
            case (find_state)
                2'b00: begin          
                                                     
                        if(find_start)
                        begin
                            found_in_cache = 1'b0;
                            find_state = 2'b01;                        
                            done = 1'b0;                        
                        end                            
                       end
                       
                2'b01: begin
                       
                       if (done)
                       begin
                           find_state = 2'b10;
                           count = 0;
                       end     
                       else
                       begin
                          // to check if there is hit in cache 
                          msb_indexbit = msb_index[set_index];
                          index[set_index-1:0] = msb_index[set_index-1:0];                          
                          if (L2_found_in_cache)
                          begin
                              if (msb_indexbit)
                              begin                          
                                 if(mask1[index][hit_way])
                                 begin                            
                                    temp_source = 1'b1;                         
                                    found_in_cache = 1'b1;
                                 end                               
                              end
                              else if (!msb_indexbit)
                              begin                                                    
                                 if(mask0[index][hit_way]) // mask0[0][16]
                                 begin                           
                                    temp_source = 1'b0;
                                    found_in_cache = 1'b1;
                                 end   
                              end
                              if (found_in_cache)                      
                              begin                         
                                 way_index = 0;
                                 if(temp_source)
                                 begin
                                    for(way_index=0;way_index<way;way_index=way_index+1)
                                    begin
                                        if(source[index][way_index][2] && source[index][way_index][0] && count<hit_way+1)
                                            count = count + 1;
                                        if(count==hit_way+1)
                                        begin
                                            if(!source[index][way_index][1] && ins_type) // check if there was load prior to store for same address then change dirty bit to 1
                                                source[index][way_index][1] = 1'b1;                                        
                                            temp_data =  source[index][way_index]; 
                                            hit_source = way_index;
                                            count = count + 1;
                                        end                                    
                                    end               
                                 end
                                 else if (!temp_source)
                                 begin
                                    for(way_index=0;way_index<way;way_index=way_index+1)
                                    begin
                                        if(source[index][way_index][2] && !source[index][way_index][0] && count<hit_way+1)
                                            count = count + 1;
                                        if(count==hit_way+1)
                                        begin
                                            if(!source[index][way_index][1] && ins_type) // check if there was load prior to store for same address then change dirty bit to 1
                                                source[index][way_index][1] = 1'b1;                                                                                                                    
                                            temp_data =  source[index][way_index]; 
                                            hit_source = way_index;
                                            count = count + 1;
                                        end                                    
                                    end                                                   
                                 end                                                         
                                 
                                    if (hit_source>=0 && hit_source<4)
                                    begin
                                        cache_hit_count4 = cache_hit_count4 + 1;
                                        cache_hit_count8 = cache_hit_count8 + 1;
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                    else if (hit_source>=4 && hit_source<8)
                                    begin
                                        cache_hit_count8 = cache_hit_count8 + 1;
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                    else if (hit_source>=8 && hit_source<16)
                                    begin                                    
                                        cache_hit_count16 = cache_hit_count16 + 1;
                                    end
                                 way_index = hit_source;
                                 done = 1'b1;                              
                            end
                            else
                            begin                                                          
                             hit_source = way;
                             done = 1'b1;      
                            end

                          end
                          
                          else
                          begin                            
                             hit_source = way;
                             done = 1'b1;      
                          end
                       end     
                       end
               2'b10: begin
                      
                      if(updated)
                      begin
                        find_state = 2'b00;
                        updated = 1'b0;
                        count = 0;
                      end
                      else
                      begin
                        if(found_in_cache)
                        begin
                           // Step1: update the mask registers 
                           if(msb_indexbit && !msb_update && !mask_update)
                           begin
                              if(way_index != 0)
                              begin
                                mask1[index][way_index] = mask1[index][way_index-1];
                                way_index = way_index - 1;
                              end
                              else
                              begin            
                                mask1[index][0] = 1'b1;
                                msb_update = 1'b1;
                              end                                                                                                                               
                                                               
                           end
                           else if (!msb_indexbit && !msb_update && !mask_update)
                           begin
                              if(way_index != 0)
                              begin
                                mask0[index][way_index] = mask0[index][way_index-1];
                                way_index = way_index - 1;
                              end
                              else
                              begin            
                                mask0[index][0] = 1'b1;
                                msb_update = 1'b1;                                
                              end                                                                                                                               
                                                               
                           end
                           
                           // Step2: After update, check if total 1's in mask register is <= way. If >way then update the mask register according to LRU policy.
                           if (msb_update && !mask_update)
                           begin
                            for(way_index=0;way_index<way;way_index=way_index+1)
                            begin
                                if(mask0[index][way_index])
                                    count = count + 1;
                                if(mask1[index][way_index])
                                    count = count + 1;    
                            end                                                       
                            
                            // if count>way then we have to change one of mask from 1 to 0 based on LRU
                            if(count>way)
                            begin
                                if(source[index][way-1][2] && source[index][way-1][0])
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask1[index][way_index])
                                        way_index = way_index - 1;
                                    mask1[index][way_index] = 1'b0;                                   
                                end
                                else if (source[index][way-1][2] && !source[index][way-1][0])
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask0[index][way_index])
                                        way_index = way_index - 1;
                                    mask0[index][way_index] = 1'b0;                                
                                end    
                            end
                            mask_update = 1'b1;
                            way_index = hit_source;
                            msb_update = 1'b0;
                           end
                           if(mask_update)
                           begin
                               if(way_index != 0)
                               begin
                                    source[index][way_index] = source[index][way_index-1];
                                    way_index = way_index - 1;
                               end
                               else
                               begin
                                    mask_update = 1'b0;                                           
                                    source[index][0] = temp_data;
                                    updated = 1'b1;
                               end                                                                                                                               
                           end                                                      
                        end                   
                        else // cache miss
                        begin
                                                                       
                            // Step1: update mask register
                            if(msb_indexbit)
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                    mask1[index][way_index+1] = mask1[index][way_index];
                                mask1[index][1] = mask1[index][0];
                                mask1[index][0] = 1'b1;                                  
                            end
                            else
                            begin
                                for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                    mask0[index][way_index+1] = mask0[index][way_index];
                                mask0[index][1] = mask0[index][0];
                                mask0[index][0] = 1'b1;           
                            end
                            
                            // Step2: After update, check if total 1's in mask register is <= way. If >way then update the mask register according to LRU policy.                        
                            for(way_index=0;way_index<way;way_index=way_index+1)
                            begin
                                if(mask0[index][way_index])
                                    count = count + 1;
                                if(mask1[index][way_index])
                                    count = count + 1;    
                            end                                                       
                            
                            // if count>way then we have to change one of mask from 1 to 0 based on LRU
                            if(count>way)
                            begin
                                if(source[index][way-1] == 2'b11)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask1[index][way_index])
                                        way_index = way_index - 1;
                                    mask1[index][way_index] = 1'b0;                                   
                                end
                                else if (source[index][way-1] == 2'b10)
                                begin
                                    way_index = way-1;
                                    while(way_index>0 && !mask0[index][way_index])
                                        way_index = way_index - 1;
                                    mask0[index][way_index] = 1'b0;                                
                                end    
                            end
                            
                             // update source register
                            for(way_index=way-2;way_index>0;way_index=way_index-1)                                         
                                source[index][way_index+1] = source[index][way_index];                                                                                               
                            source[index][1] = source[index][0];
                            if (!ins_type)   // Load instruction
                                source[index][0] = {1'b1,1'b0,msb_indexbit};
                            else            // Store instruction
                                source[index][0] = {1'b1,1'b1,msb_indexbit};                                                               
                            updated = 1'b1;
                                    
                        end
                      end
               
                      end
                                  
            endcase
         end                 
    end    
endmodule