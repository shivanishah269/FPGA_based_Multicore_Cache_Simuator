`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2020 11:26:40
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
    reg [11:0] cache_addr;
    reg [157:0] cache_in;
    wire [157:0] cache_out;
    
    // temporary variables for cache data
    reg [2:0] flag;
    reg done;
    
    // temporary variables for update cache 
    reg [28:0] temp_tag;
    reg [127:0] temp_data;
    
    blk_mem_gen_0 cache (
      .clka(clk2),    // input wire clka
      .ena(ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(cache_addr),  // input wire [11 : 0] addra
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
        ena = 1'b1;
    end
     
    always @ (posedge clk2)
    begin 
        if(reset)
        begin
            found_in_cache = 1'b0;
            flag = 0;
            updated = 0;
            done = 0;
        end
        else
        begin
            if (!done)
            begin
                wea = 1'b0;
                cache_addr = index;
                if(flag > 2) 
                begin    
                    if(cache_out[157])
                    begin
                        if(cache_out[156:128]==tag)
                        begin
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
