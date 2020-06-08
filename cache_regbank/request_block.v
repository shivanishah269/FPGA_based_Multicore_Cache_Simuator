`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.06.2020 12:25:07
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


module request_block(clk3,reset,found_in_cache,tag,index,block_offset,block,block_ready);

    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    
    input clk3,reset,found_in_cache;
    input [15-set_index-block_offset_index:0] tag; 
    input [set_index-1:0] index; 
    input [block_offset_index-1:0] block_offset;
    output reg [(block_size_byte*8)-1:0] block;
    output reg block_ready;
    
    
    reg ena;
    reg [15:0] memory_addr;
    wire [7:0] mem_out;
    
    blk_mem_gen_0 memory (
      .clka(clk3),    // input wire clka
      .ena(ena),      // input wire ena
      .addra(memory_addr),  // input wire [15 : 0] addra
      .douta(mem_out)  // output wire [7 : 0] douta
    );
    
    reg [5:0] i;
    reg [4:0] flag;
    
    initial 
    begin
        flag = 0;
        block = 0;
        i = 0;
        block_ready = 0;
    end
    
    
    always @ (posedge clk3)
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
                        block_ready = 1'b0;
               end
                 
               else if(block_offset_index==3)
               begin
                    if (i<=7)
                    begin
                        memory_addr = {tag,index,i[2:0]};
                        i = i + 1;   
                    end
                    
                    if(flag<8 && i>3)
                    begin
                        block = {mem_out,block[(block_size_byte*8)-1:8]};
                        flag = flag + 1;
                        if(flag==8)                    
                            block_ready = 1'b1;
                    end                 
                    else 
                        block_ready = 1'b0;
               end
               
               else if(block_offset_index==4)
               begin
                    if (i<=15)
                    begin
                        memory_addr = {tag,index,i[3:0]};
                        i = i + 1;   
                    end
                    
                    if(flag<16 && i>3)
                    begin
                        block = {mem_out,block[(block_size_byte*8)-1:8]};
                        flag = flag + 1;
                        if(flag==16)                    
                            block_ready = 1'b1;
                    end                 
                    else 
                        block_ready = 1'b0;
               end         
            end
        end
    end
    
endmodule
