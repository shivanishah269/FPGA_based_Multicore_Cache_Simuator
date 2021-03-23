`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.02.2021 13:36:49
// Design Name: 
// Module Name: NLP_Prefetcher
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


module prefetcher (clk,address,cache_miss,prefetch_hit);

    parameter way = 4;
    parameter block_size_byte = 16;
    parameter cache_size_byte = 1*1024;
    parameter way_width = $rtoi($ln(way)/$ln(2));
    
    parameter block_offset_index = $rtoi($ln(block_size_byte)/$ln(2));  //2
    parameter set = cache_size_byte/(block_size_byte*way); 
    parameter set_index = $rtoi($ln(set)/$ln(2));
     
    parameter prefetch_width = 32-block_offset_index  + 1; // without data (tag+index+valid) 
    
    input clk,cache_miss;
    input [31:0]address;
    output reg prefetch_hit;
    
    wire [31-set_index-block_offset_index:0] tag;      // 23 bits..22:0
    wire [set_index-1:0] index;                        //7 bits...6:0
    wire [block_offset_index-1:0] block_offset;         //2 bits...1:0
    
     
    wire [set_index-1:0]temp_index;
    wire [5:0]prefetch_fill_index;
    wire valid_buffer_check, valid_fill_check;
    
    reg [prefetch_width-1:0]prefetch_buffer[0:7];
    wire [2:0] hit_index;
    reg [1:0] find_state;
    reg [3:0] way_index;
    reg done,updated;
    reg [prefetch_width-1:0] temp_data;
    integer k;
     
     assign block_offset = address[block_offset_index-1:0];
     assign index = address[set_index+block_offset_index-1:block_offset_index];
     assign tag =address[31:set_index+block_offset_index];
     assign temp_index = index + 1'b1;
         
     assign valid_buffer_check = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]==address[31:block_offset_index])) || (prefetch_buffer[7][prefetch_width-1] && (prefetch_buffer[7][prefetch_width-2:0]==address[31:block_offset_index])); 
     
     assign hit_index = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b000 :     
                        (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b001 :
                        (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b010 :
                        (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b011 : 
                        (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b100 :
                        (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b101 :
                        (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]==address[31:block_offset_index])) ? 3'b110 : 3'b111;
                        
     
     assign valid_fill_check = (prefetch_buffer[0][prefetch_width-1] && (prefetch_buffer[0][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[1][prefetch_width-1] && (prefetch_buffer[1][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[2][prefetch_width-1] && (prefetch_buffer[2][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[3][prefetch_width-1] && (prefetch_buffer[3][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[4][prefetch_width-1] && (prefetch_buffer[4][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[5][prefetch_width-1] && (prefetch_buffer[5][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[6][prefetch_width-1] && (prefetch_buffer[6][prefetch_width-2:0]=={tag,temp_index})) || (prefetch_buffer[7][prefetch_width-1] && (prefetch_buffer[7][prefetch_width-2:0]=={tag,temp_index}));  
     
     initial
     begin
        for (k=0;k<8;k=k+1)
            prefetch_buffer[k] = 0;
        done = 0;
        updated = 0;
        prefetch_hit = 0;
        find_state = 0;        
    end
    
    always @ (posedge clk)
    begin
        case(find_state)
            2'b00: begin
                    done = 1'b0;
                    if(cache_miss)
                    begin
                        prefetch_hit = 1'b0;
                        find_state = 2'b01;
                    end    
                  end
                  
            2'b01: begin
                    if(done)
                        find_state = 2'b10;
                    else
                    begin                                           
                        if(valid_buffer_check)
                        begin
                            prefetch_hit = 1'b1;
                            done = 1'b1;
                        end
                        else 
                        begin
                            done =1'b1;
                            prefetch_hit=1'b0;
                        end
                     end                                                        
                   end
            
            2'b10: begin
                    if(updated)
                    begin
                        find_state = 2'b00;
                        updated = 1'b0;
                    end
                    else
                    begin
                        if(!prefetch_hit)
                        begin
                            if(valid_fill_check)
                                updated = 1'b1;
                            else
                            begin    
                                prefetch_buffer[7] = prefetch_buffer[6];
                                prefetch_buffer[6] = prefetch_buffer[5];
                                prefetch_buffer[5] = prefetch_buffer[4];
                                prefetch_buffer[4] = prefetch_buffer[3];
                                prefetch_buffer[3] = prefetch_buffer[2];
                                prefetch_buffer[2] = prefetch_buffer[1];
                                prefetch_buffer[1] = prefetch_buffer[0];
                                prefetch_buffer[0] = {1'b1,tag,temp_index};
                                updated = 1'b1;
                             end                                                                     
                        end
                        
                        if(prefetch_hit)
                        begin
                            temp_data = prefetch_buffer[hit_index];
                            for (way_index=0;way_index<hit_index;way_index=way_index+1)
                                prefetch_buffer[hit_index-way_index]= prefetch_buffer[hit_index-way_index-1];
                            prefetch_buffer[0] = temp_data;
                                                        
                            updated = 1'b1;             
                        end
                    end
                   end       
        endcase
    end
endmodule
