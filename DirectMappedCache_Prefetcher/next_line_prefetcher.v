`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.09.2020 15:51:51
// Design Name: 
// Module Name: next_line_prefetcher
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


module next_line_prefetcher (clk,address,block,cache_miss,block_ready,prefetch_address,prefetch_hit,prefetch_data,prefetch_miss);

    parameter way = 1;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 32*1024;
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));  //2
    parameter cache_lines = cache_size_byte/(block_size_byte);          //2^7
    parameter line_index = $rtoi($ln(cache_lines)/$ln(2));              //7
       
    parameter prefetch_width = 32-block_offset_index + block_size_byte*8  + 1; 
    
    input clk,cache_miss;
    input [31:0]address;
    input [(block_size_byte*8)-1:0] block;
    input block_ready;
    output reg [31:0]prefetch_address;
    output reg prefetch_miss,prefetch_hit;
    output reg [(block_size_byte*8)-1:0] prefetch_data;
    
    wire [31-line_index-block_offset_index:0] tag;      // 23 bits..22:0
    wire [line_index-1:0] index;                        //7 bits...6:0
    wire [block_offset_index-1:0] block_offset;         //2 bits...1:0
    
     
    wire [line_index-1:0]temp_index;
    wire [5:0]prefetch_fill_index;
    wire valid_check;
    wire prefetch_buffer_check;
    
    reg [prefetch_width-1:0]prefetch_buffer[0:7];
    reg [31:0] memory_addr;
    reg [31:0]temp_data;
    reg [7:0]i;
    reg find_state,update_state,data_ready;
    reg done,done1;
    integer k;
     
     assign block_offset = address[block_offset_index-1:0];
     assign index = address[line_index+block_offset_index-1:block_offset_index];
     assign tag =address[31:line_index+block_offset_index];
     assign temp_index = index + 1'b1;
     
     assign prefetch_fill_index = prefetch_buffer[0][prefetch_width-1]?(prefetch_buffer[1][prefetch_width-1]?(prefetch_buffer[2][prefetch_width-1]?(prefetch_buffer[3][prefetch_width-1]?(prefetch_buffer[4][prefetch_width-1]?(prefetch_buffer[5][prefetch_width-1]?(prefetch_buffer[6][prefetch_width-1]?(prefetch_buffer[7][prefetch_width-1]?(5'b00000):5'b00111):5'b00110):5'b00101):5'b00100):5'b00011):5'b00010):5'b00001):5'b00000;
     assign valid_check = prefetch_buffer[0][prefetch_width-1] || prefetch_buffer[1][prefetch_width-1] || prefetch_buffer[2][prefetch_width-1] || prefetch_buffer[3][prefetch_width-1] || prefetch_buffer[4][prefetch_width-1] || prefetch_buffer[5][prefetch_width-1] || prefetch_buffer[6][prefetch_width-1] || prefetch_buffer[7][prefetch_width-1];
     assign prefetch_buffer_check =(prefetch_buffer[0][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) ||(prefetch_buffer[1][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) || (prefetch_buffer[2][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) || (prefetch_buffer[3][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) || (prefetch_buffer[4][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) || (prefetch_buffer[5][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) ||(prefetch_buffer[6][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]) || (prefetch_buffer[7][prefetch_width-2:(block_size_byte*8)]==address[31:block_offset_index]);
     
     initial
     begin
        for (k=0;k<8;k=k+1)
            prefetch_buffer[k] = 0;
        i=0;
        done=0;
        done1=0;
        temp_data=0;
        data_ready=0;
        prefetch_hit=0;
        prefetch_miss=0;
        memory_addr=0;
        find_state = 0;
        update_state = 0;
    end
    
    always @ (posedge clk)
    begin
         prefetch_address = ((address>>block_offset_index)+1) << block_offset_index;
        case(find_state)
            1'b0: begin
                    done = 1'b0;
	                prefetch_hit = 1'b0;
	                prefetch_miss = 1'b0;
                    if(cache_miss)
                    begin
                        find_state = 1'b1;
                    end    
                  end
            1'b1: begin
                    if(done)
                        find_state = 1'b0;
                    else
                    begin               
                            if(valid_check)
                            begin
                                if(prefetch_buffer_check)
                                begin
                                    prefetch_hit = 1'b1;
                                    done = 1'b1;
                                    //move this data into cache
                                    prefetch_data = 0;
                                end
                                else 
                                begin
                                    done =1'b1;
                                    prefetch_miss=1'b1;
                                end
                            end
                            else
                            begin
                                done =1'b1;
                                prefetch_miss=1'b1;
                            end 
                            
                        end
                    end
        endcase

        case (update_state)
            1'b0: begin
                    data_ready = 1'b0;
                    done1=1'b0;
                    if (prefetch_miss)
                        update_state = 1'b1;
                    end
            1'b1: begin
                     if(done1)
                        update_state = 1'b0;
                     else
                     begin
                        if(block_ready) // block_ready_prefetcher
                        begin
                            prefetch_buffer[prefetch_fill_index]={1'b1,tag,temp_index,block};
                            done1=1'b1;
                        end
                     end
                  end
          endcase
        end
endmodule