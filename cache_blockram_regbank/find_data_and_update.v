`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.06.2020 12:26:42
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
    
    // Block Ram varibles
    reg ena,wea;
    reg [10:0] cache_addr;
    reg [157:0] cache_in;
    wire [157:0] cache_out;
    
    // temporary variables for cache data
    reg [2:0] flag;
    reg done;
    
    // temporary variables for update cache 
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    
    reg [168:0] local_cache [0:15];
    reg [15:0] done_lc;
    reg [3:0] lc_index;
    reg [4:0] i;
    
    blk_mem_gen_2 cache (
      .clka(clk2),    // input wire clka
      .ena(ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(cache_addr),  // input wire [10: 0] addra
      .dina(cache_in),    // input wire [157 : 0] dina
      .douta(cache_out)  // output wire [157 : 0] douta
    );
    
    initial 
    begin
        found_in_cache = 0;
        flag = 0;
        done = 0;
        cache_hit = 0;
        updated = 0;
        cache_miss = 0;
        temp_tag = 0;
        temp_data = 0;
        done_lc = 0;
        ena = 1'b1;
        for(i=0;i<16;i=i+1)
            local_cache[i] = 0;
    end
     
    always @ (posedge clk2)
    begin 
        if(reset)
        begin
            found_in_cache = 1'b0;
            flag = 0;
            updated = 0;
            done = 0;
            done_lc = 0;
        end
        else
        begin
            if (!done)
            begin
                
                if(local_cache[0][168])
                begin
                    if(local_cache[0][167:157]==index)
                    begin
                        if(local_cache[0][156:128]==tag)
                        begin
                            found_in_cache = 1'b1;
                            cache_hit = cache_hit + 1'b1;
                            done = 1'b1;
                        end
                    end
                    else if(local_cache[1][168])
                    begin
                        if(local_cache[1][167:157]==index)
                        begin
                            if(local_cache[1][156:128]==tag)
                            begin
                                found_in_cache = 1'b1;
                                cache_hit = cache_hit + 1'b1;
                                done = 1'b1;
                            end
                        end
                        else if (local_cache[2][168])
                        begin
                            if(local_cache[2][167:157]==index)
                            begin
                                if(local_cache[2][156:128]==tag)
                                begin
                                    found_in_cache = 1'b1;
                                    cache_hit = cache_hit + 1'b1;
                                    done = 1'b1;
                                end
                            end
                            else if (local_cache[3][168])
                            begin
                                if(local_cache[3][167:157]==index)
                                begin
                                    if(local_cache[3][156:128]==tag)
                                    begin
                                        found_in_cache = 1'b1;
                                        cache_hit = cache_hit + 1'b1;
                                        done = 1'b1;
                                    end
                                end
                                else if (local_cache[4][168])
                                begin
                                    if(local_cache[4][167:157]==index)
                                    begin
                                        if(local_cache[4][156:128]==tag)
                                        begin
                                            found_in_cache = 1'b1;
                                            cache_hit = cache_hit + 1'b1;
                                            done = 1'b1;
                                        end
                                    end
                                    else if (local_cache[5][168])
                                    begin
                                        if(local_cache[5][167:157]==index)
                                        begin
                                            if(local_cache[5][156:128]==tag)
                                            begin
                                                found_in_cache = 1'b1;
                                                cache_hit = cache_hit + 1'b1;
                                                done = 1'b1;
                                            end
                                        end
                                        else if (local_cache[6][168])
                                        begin
                                            if(local_cache[6][167:157]==index)
                                            begin
                                                if(local_cache[6][156:128]==tag)
                                                begin
                                                    found_in_cache = 1'b1;
                                                    cache_hit = cache_hit + 1'b1;
                                                    done = 1'b1;
                                                end
                                            end
                                            else if (local_cache[7][168])
                                            begin
                                                if(local_cache[7][167:157]==index)
                                                begin
                                                    if(local_cache[7][156:128]==tag)
                                                    begin
                                                        found_in_cache = 1'b1;
                                                        cache_hit = cache_hit + 1'b1;
                                                        done = 1'b1;
                                                    end
                                                end
                                                else if (local_cache[8][168])
                                                begin
                                                    if(local_cache[8][167:157]==index)
                                                    begin
                                                        if(local_cache[8][156:128]==tag)
                                                        begin
                                                            found_in_cache = 1'b1;
                                                            cache_hit = cache_hit + 1'b1;
                                                            done = 1'b1;
                                                        end
                                                    end
                                                    else if (local_cache[9][168])
                                                    begin
                                                        if(local_cache[9][167:157]==index)
                                                        begin
                                                            if(local_cache[9][156:128]==tag)
                                                            begin
                                                                found_in_cache = 1'b1;
                                                                cache_hit = cache_hit + 1'b1;
                                                                done = 1'b1;
                                                            end
                                                        end
                                                        else if (local_cache[10][168])
                                                        begin
                                                            if(local_cache[10][167:157]==index)
                                                            begin
                                                                if(local_cache[10][156:128]==tag)
                                                                begin
                                                                    found_in_cache = 1'b1;
                                                                    cache_hit = cache_hit + 1'b1;
                                                                    done = 1'b1;
                                                                end
                                                            end
                                                            else if (local_cache[11][168])
                                                            begin
                                                                if(local_cache[11][167:157]==index)
                                                                begin
                                                                    if(local_cache[11][156:128]==tag)
                                                                    begin
                                                                        found_in_cache = 1'b1;
                                                                        cache_hit = cache_hit + 1'b1;
                                                                        done = 1'b1;
                                                                    end
                                                                end
                                                                else if (local_cache[12][168])
                                                                begin
                                                                    if(local_cache[12][167:157]==index)
                                                                    begin
                                                                        if(local_cache[12][156:128]==tag)
                                                                        begin
                                                                            found_in_cache = 1'b1;
                                                                            cache_hit = cache_hit + 1'b1;
                                                                            done = 1'b1;
                                                                        end
                                                                    end
                                                                    else if (local_cache[13][168])
                                                                    begin
                                                                        if(local_cache[13][167:157]==index)
                                                                        begin
                                                                            if(local_cache[13][156:128]==tag)
                                                                            begin
                                                                                found_in_cache = 1'b1;
                                                                                cache_hit = cache_hit + 1'b1;
                                                                                done = 1'b1;
                                                                            end
                                                                        end
                                                                        else if (local_cache[14][168])
                                                                        begin
                                                                            if(local_cache[14][167:157]==index)
                                                                            begin
                                                                                if(local_cache[14][156:128]==tag)
                                                                                begin
                                                                                    found_in_cache = 1'b1;
                                                                                    cache_hit = cache_hit + 1'b1;
                                                                                    done = 1'b1;
                                                                                end
                                                                            end
                                                                            else if (local_cache[15][168])
                                                                            begin
                                                                                if(local_cache[15][167:157]==index)
                                                                                begin
                                                                                    if(local_cache[15][156:128]==tag)
                                                                                    begin
                                                                                        found_in_cache = 1'b1;
                                                                                        cache_hit = cache_hit + 1'b1;
                                                                                        done = 1'b1;
                                                                                    end
                                                                                end                                                                                                                                                               end
                                                                            else
                                                                                lc_index = 15;    
                                                                        end
                                                                        else
                                                                            lc_index = 14;    
                                                                    end
                                                                    else
                                                                        lc_index = 13;    
                                                                end
                                                                else
                                                                    lc_index = 12;    
                                                            end
                                                            else
                                                                lc_index = 11;    
                                                        end
                                                        else
                                                            lc_index = 10;    
                                                    end
                                                    else
                                                        lc_index = 9;        
                                                end
                                                else
                                                    lc_index = 8;    
                                            end
                                            else
                                                lc_index = 7;    
                                        end
                                        else
                                            lc_index = 6;    
                                    end
                                    else
                                        lc_index = 5;    
                                end
                                else
                                    lc_index = 4;    
                            end
                            else
                                lc_index = 3;    
                        end
                        else 
                            lc_index = 2;    
                    end
                    else
                        lc_index = 1;
                end
                else
                    lc_index = 0;
                
                
                if(!found_in_cache)
                begin
                    wea = 1'b0;
                    cache_addr = index;
                    if(flag > 2) 
                    begin    
                        if(cache_out[157])
                        begin
                            if(cache_out[156:128]==tag)
                            begin
                                local_cache[lc_index] = {1'b1,index,cache_out[156:128],cache_out[127:0]};
                                found_in_cache = 1'b1;
                                cache_hit = cache_hit + 1'b1;
                            end            
                        end
                        else
                            found_in_cache = 1'b0;
                        done = 1'b1;           
                    end
                    else
                        flag = flag + 1;
              end  
            end        
               if(control)
               begin
                   wea = 1'b1;
                   cache_addr = index;
                   temp_tag = tag;
                   temp_data = block;
                   cache_in = {1'b1,temp_tag,temp_data};
                   updated = 1'b1;
                   cache_miss = cache_miss + 1;
              end
        end
    end
endmodule
