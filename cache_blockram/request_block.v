`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.05.2020 11:26:40
// Design Name: 
// Module Name: request_block
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


module request_block(clk,reset,found_in_cache,tag,index,block_offset,block,block_ready);

parameter way = 16;
parameter block_size_byte = 4;
parameter cache_size_byte = 64*1024;

parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
parameter set = cache_size_byte/(block_size_byte*way); 
parameter set_index = $rtoi($ln(set)/$ln(2));

input clk,reset,found_in_cache;
input [15-set_index-block_offset_index:0] tag; 
input [set_index-1:0] index; 
input [block_offset_index-1:0] block_offset;
output reg [(block_size_byte*8)-1:0] block;
output reg block_ready;


reg ena;
reg [15:0] memory_addr;
wire [7:0] mem_out;

blk_mem_gen_1 memory (
  .clka(clk),    // input wire clka
  .ena(ena),      // input wire ena
  .addra(memory_addr),  // input wire [15 : 0] addra
  .douta(mem_out)  // output wire [7 : 0] douta
);

reg [6:0] i;
reg [6:0] flag;

initial 
begin
    flag = 0;
    block = 0;
    i = 0;
    block_ready = 0;
    //memory_addr = 0;
end


always @ (posedge clk)
begin
    ena = 1'b1;
    if(reset)
    begin
        i = 0;
        block = 0;
        flag = 0;
        block_ready = 0;
    end
    else
    begin
        if (!found_in_cache)
        begin   
            if (block_offset_index == 2)
            begin           
                if (i<=3) 
                begin
                    memory_addr = {tag,index,i[1:0]};
                    i = i + 1;   
                end
                
                if(flag<4 && i>3) 
                begin
                    block = {mem_out,block[(block_size_byte*8)-1:8]};
                    flag = flag + 1;
                    if (flag==4)
                        block_ready = 1'b1;
                end
                else
                    block_ready = 0;
           end 
           /*  
           else if(block_offset_index==3)
           begin
                if (i<=7)
                begin
                    memory_addr = {tag,index,i};
                    i = i + 1;   
                end
                
                if(flag<8 && i>3)
                begin
                    block = {mem_out,block[(block_size_byte*8)-1:8]};
                    flag = flag + 1;
                end 
                
                if(flag==8)
                begin
                    block_ready = 1'b1;
                    flag = flag + 1;
                end
                else 
                    block_ready = 1'b0;
           end */    
        end
     end
    
end

endmodule
