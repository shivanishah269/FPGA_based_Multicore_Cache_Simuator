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


module request_block(clk,tag,index,block_offset,start,trace_ready,block,block_ready,miss_latency);
    
    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));

    
    input clk,start,trace_ready;
    input [15-set_index-block_offset_index:0] tag;
    input [set_index-1:0] index;
    input [block_offset_index-1:0] block_offset;
    output reg [(block_size_byte*8)-1:0] block;
    output reg block_ready;
    output reg [4:0] miss_latency;
      
    reg ena;
    reg [15:0] memory_addr;
    wire [7:0] mem_out;
    
    blk_mem_gen_0 memory (
      .clka(clk),    // input wire clka
      .ena(ena),      // input wire ena
      .addra(memory_addr),  // input wire [15 : 0] addra
      .douta(mem_out)  // output wire [7 : 0] douta
    );
    
    reg [5:0] i;
    reg [4:0] flag;
    reg state;
    
    initial 
    begin
        flag = 0;
        block = 0;
        i = 0;
        block_ready = 0;
        ena = 1'b0;
        state = 0;
        miss_latency = 0;
    end
    
    
    always @ (posedge clk)
    begin
        case (state)
            1'b0: begin
                    i = 0;
                    //block = 0;
                    flag = 0;
                    block_ready = 0;
                    ena = 1'b0;
                    if(trace_ready)
                        miss_latency = 0;   
                    if(start)
                    begin
                        state = 1'b1;
                        block = 0;
                        miss_latency = miss_latency + 5; // 1 cycle - generates address 3 cycle - generates data from that particular address 1 cycle - cache latency added  
                    end  
                  end
            1'b1: begin
                    ena = 1'b1;
                    if(block_ready)
                    begin
                        state = 1'b0;
                        miss_latency = miss_latency + 1'b1; // 1 cycle added for updating in cache when the block is ready
                    end 
                    else
                        if (i<=block_size_byte-1) 
                        begin
                            memory_addr = {tag,index,i[block_offset_index-1:0]}; 
                            i = i + 1;   
                        end                    
                        if(flag<block_size_byte && i>3) 
                        begin
                            block = {mem_out,block[((block_size_byte)*8)-1:8]};
                            flag = flag + 1;
                            if (flag==block_size_byte)
                                block_ready = 1'b1;
                            miss_latency = miss_latency + 1'b1;
                        end
                        else
                            block_ready = 1'b0;      
                  end    
        endcase
    end
    
endmodule
