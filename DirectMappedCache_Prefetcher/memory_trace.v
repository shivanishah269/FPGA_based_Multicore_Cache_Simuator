`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.09.2020 15:51:51
// Design Name: 
// Module Name: memory_trace
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


module memory_trace(clk,start,next_trace,done);

    input clk,start;
    output [15:0] next_trace;
    output reg done;
    
    reg ena;
    reg [15:0] addr;
    reg state;
    reg [2:0] flag;
    
    
    blk_mem_gen_1 mem_trace (
    .clka(clk),    // input wire clka
    .ena(ena),      // input wire ena
    .addra(addr),  // input wire [15 : 0] addra
    .douta(next_trace)  // output wire [15 : 0] douta
    );
    
    initial
    begin
        addr = {16{1'b0}};
        state = 1'b1;
        done = 1'b1;
        ena = 1'b1;
        flag = 3'b000;
    end
            
    always @ (posedge clk)
    begin
        case (state)
            1'b0: begin
                    flag = 3'b000;
                    if(start)
                    begin
                        state = 1'b1;
                        done = 1'b0;
                    end  
                  end
            1'b1: begin
                    if(done)
                    begin
                        state = 1'b0;
                        done = 1'b0;
                    end    
                    else
                    begin
                        if(!flag)
                        begin
                            addr = addr + 1'b1;
                            flag = flag + 1'b1;
                        end    
                        else if (flag>3)
                            done = 1'b1;    
                        else
                            flag = flag + 1'b1;
                    end
                  end
        endcase
        
    end
    
endmodule