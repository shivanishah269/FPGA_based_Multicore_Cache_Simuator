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


module find_data_and_update(clk,reset,control,tag,index,block_offset,block,cache_hit,cache_miss,updated,found_in_cache);

parameter way = 16;
parameter block_size_byte = 4;
parameter cache_size_byte = 64*1024;

parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
parameter set = cache_size_byte/(block_size_byte*way); 
parameter set_index = $rtoi($ln(set)/$ln(2));
parameter init_file = "";


input clk,control,reset;
input [31-set_index-block_offset_index:0] tag;
input [set_index-1:0] index;
input [block_offset_index-1:0] block_offset;
input [(block_size_byte*8)-1:0] block;
output reg updated,found_in_cache;
output reg [15:0] cache_hit,cache_miss;

// Block Ram varibles
reg ena,wea;
reg [12:0] cache_addr;
reg [541:0] cache_in;
wire [541:0] cache_out;

// temporary variables for cache data
reg [541:0] temp_cachedata;
reg [2:0] flag;
reg done;

// temporary variables for update cache 
reg [12:0] addr;
reg [28:0] temp_tag;
reg [511:0] temp_data;

blk_mem_gen_0 cache_update (
  .clka(clk),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(cache_addr),  // input wire [12 : 0] addra
  .dina(cache_in),    // input wire [541 : 0] dina
  .douta(cache_out)  // output wire [541 : 0] douta
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
end

always @ (posedge clk)
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
            ena = 1'b1;
            wea = 1'b0;
            cache_addr = index;
            
            if(flag > 3) // flag doesn't go to 5
            begin
                temp_cachedata = cache_out;
                if(temp_cachedata[541])
                begin
                    if(temp_cachedata[540:512]==tag)
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
            ena = 1'b1;
            wea = 1'b1;
            addr = index;
            temp_tag = tag;
            temp_data = block;
            cache_addr = addr;
            cache_in = {1'b1,temp_tag,temp_data};
            updated = 1'b1;
            cache_miss = cache_miss + 1;
        end
    end
end

endmodule
