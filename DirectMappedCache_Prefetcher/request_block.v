`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.09.2020 15:51:51
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


module request_block(clk,start_cache,start_prefetch,trace_ready,tag,index,block_offset,prefetch_address,block_cache,block_prefetch,block_ready_cache,block_ready_prefetch,miss_latency);
    
    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
    
    input clk,start_cache,start_prefetch,trace_ready;
    input [15-set_index-block_offset_index:0] tag; 
    input [set_index-1:0] index; 
    input [block_offset_index-1:0] block_offset;
    input [31:0] prefetch_address;
    output reg [(block_size_byte*8)-1:0] block_cache,block_prefetch;
    output reg block_ready_cache,block_ready_prefetch;
    output reg [4:0] miss_latency;
      
    reg en_cache,en_prefetch;
    reg [15:0] addr_cache,addr_prefetch;
    wire [7:0] dout_cache,dout_prefetch;
    
    blk_mem_gen_0 your_instance_name (
      .clka(clk),    // input wire clka
      .ena(en_cache),      // input wire ena
      .addra(addr_cache),  // input wire [15 : 0] addra
      .douta(dout_cache),  // output wire [7 : 0] douta
      .clkb(clk),    // input wire clkb
      .enb(en_prefetch),      // input wire enb
      .addrb(addr_prefetch),  // input wire [15 : 0] addrb
      .doutb(dout_prefetch)  // output wire [7 : 0] doutb
    );
    
    reg [5:0] i,j;
    reg [4:0] flag_cache,flag_prefetch;
    reg state_cache,state_prefetch;
    
    initial 
    begin
        flag_cache = 0;
        block_cache = 0;
        i = 0;
        block_ready_cache = 0;
        en_cache = 1'b0;
        state_cache = 0;
        flag_prefetch = 0;
        block_prefetch = 0;
        j = 0;
        block_ready_prefetch = 0;
        en_prefetch = 1'b0;
        state_prefetch = 0;
        miss_latency = 0;
    end
    
    
    always @ (posedge clk)
    begin
        // cache 
        case (state_cache)
            1'b0: begin
                    i = 0;
                    block_cache = 0;
                    flag_cache = 0;
                    block_ready_cache = 0;
                    en_cache = 1'b0;
                    if(trace_ready)
                        miss_latency = 0;
                    if(start_cache)
                    begin
                        state_cache = 1'b1;
                        miss_latency = miss_latency + 5; // 1 cycle - generates address 3 cycle - generates data from that particular address 1 cycle - cache latency added  
                    end  
                  end
            1'b1: begin
                    en_cache = 1'b1;
                    if(block_ready_cache)
                    begin
                        state_cache = 1'b0;
                        miss_latency = miss_latency + 1'b1; // 1 cycle added for updating in cache when the block is ready
                    end 
                    else
                        if (i<=block_size_byte-1) 
                        begin
                            addr_cache = {tag,index,i[block_offset_index-1:0]}; 
                            i = i + 1;   
                        end                    
                        if(flag_cache<block_size_byte && i>3) 
                        begin
                            block_cache = {dout_cache,block_cache[(block_size_byte*8)-1:8]};
                            flag_cache = flag_cache + 1;
                            if (flag_cache==block_size_byte)
                                block_ready_cache = 1'b1;
                            miss_latency = miss_latency + 1'b1;
                        end
                        else
                            block_ready_cache = 1'b0;      
                  end    
        endcase
        
        // prefetcher
        case (state_prefetch)
            1'b0: begin
                    j = 0;
                    block_prefetch = 0;
                    flag_prefetch = 0;
                    block_ready_prefetch = 0;
                    en_prefetch = 1'b0;
                    if(trace_ready)
                        miss_latency = 0;
                    if(start_prefetch)
                    begin
                        state_prefetch = 1'b1;
                        miss_latency = miss_latency + 6; // 1 cycle - generates address 3 cycle - generates data from that particular address 1 cycle - cache latency added  - prefetcher latency added
                    end  
                  end
            1'b1: begin
                    en_prefetch = 1'b1;
                    if(block_ready_prefetch)
                    begin
                        state_prefetch = 1'b0;
                        miss_latency = miss_latency + 1'b1; // 1 cycle added for updating in prefetcher when the block is ready
                    end 
                    else
                        if (j<=block_size_byte-1) 
                        begin
                            addr_prefetch = prefetch_address + j[block_offset_index-1:0] ; 
                            j = j + 1;   
                        end                    
                        if(flag_prefetch<block_size_byte && j>2) 
                        begin
                            block_prefetch = {dout_prefetch,block_prefetch[(block_size_byte*8)-1:8]};
                            flag_prefetch = flag_prefetch + 1;
                            if (flag_prefetch==block_size_byte)
                                block_ready_prefetch = 1'b1;
                            miss_latency = miss_latency + 1'b1;
                        end
                        else
                            block_ready_prefetch = 1'b0;      
                  end    
        endcase
    end
    
endmodule