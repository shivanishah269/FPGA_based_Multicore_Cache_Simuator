`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.04.2020 13:06:56
// Design Name: 
// Module Name: test
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


module test();

reg clk;
reg [15:0] memory_trace;

wire [15:0] cache_hit, cache_miss;

main uut (clk,memory_trace,cache_hit,cache_miss);

initial begin
clk = 0;
memory_trace = 0;//0000_0000_0000_1000 miss 
#100;
memory_trace = 9;//0000_0000_0000_1001 miss 
#100; 
memory_trace = 8;//0000_0000_0000_1000 hit 
#100; 
memory_trace = 1;//0000_0000_0000_0001 hit 
#100;
memory_trace = 4;//0000_0000_0000_0100 miss 
#100;
memory_trace = 5;//0000_0000_0000_0100 miss
#100;
memory_trace = 10;//0000_0000_0000_0100 miss
#100;
memory_trace = 4;//0000_0000_0000_0100 miss
#100;
memory_trace = 12;//0000_0000_0000_0100 miss
#100;
memory_trace = 16;//0000_0000_0000_0100 miss
#100;
memory_trace = 13;//0000_0000_0000_0100 miss
#100;
memory_trace = 18;//0000_0000_0000_0100 miss

end

always #5 clk = ~ clk;
initial #1200 $finish; 

endmodule
