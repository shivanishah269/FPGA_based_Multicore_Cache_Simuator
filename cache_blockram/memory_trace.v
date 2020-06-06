`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2020 11:28:58
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


module memory_trace(clk1,start,next_trace);

    input clk1,start;
    output [15:0] next_trace;
    
    reg ena;
    reg [15:0] addr;
    
    
    blk_mem_gen_2 mem_trace (
    .clka(clk1),    // input wire clka
    .ena(ena),      // input wire ena
    .addra(addr),  // input wire [15 : 0] addra
    .douta(next_trace)  // output wire [15 : 0] douta
    );
    
    initial
    begin
        addr = {16{1'b0}};
        ena = 1'b1;
    end
            
    always @ (posedge clk1)
    begin
        if (start)
            addr = addr + 1'b1;
    end
    
endmodule
