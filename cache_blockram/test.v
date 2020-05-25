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

/*
//block_offset_bit = 2 // 4 B
//cache_miss --> 8cc from the point where it gets memory trace to cache_miss (7 (3(block ram)+4B)cc (request block) + 1 cc (to update in cache))
//cache_hit --> 4cc from the point where it gets memory trace to cache_hit (3cc(find_data) + 1cc)

//Total --> hit = 7, miss = 5
memory_trace = 0;//0000_0000_0000_0000 miss  
#90;
memory_trace = 9;//0000_0000_0000_1001 miss  
#90; 
memory_trace = 8;//0000_0000_0000_1000 hit 
#90; 
memory_trace = 1;//0000_0000_0000_0001 hit 
#90;
memory_trace = 4;//0000_0000_0000_0100 miss 
#90;
memory_trace = 5;//0000_0000_0000_0101 hit
#90;
memory_trace = 10;//0000_0000_0000_1010 hit
#90;
memory_trace = 4;//0000_0000_0000_0100 hit
#90;
memory_trace = 12;//0000_0000_0000_1100 miss 
#90;
memory_trace = 16;//0000_0000_0001_0000 miss 
#90;
memory_trace = 13;//0000_0000_0000_1101 hit 
#90;
memory_trace = 18;//0000_0000_0001_0010 hit
*/
/*
//block_offset_bit = 4 // 16 B
//cache_miss --> 20cc from the point where it gets memory trace to cache_miss (19 (3(block ram)+16B)cc (request block) + 1 cc (to update in cache))
//cache_hit --> 4cc from the point where it gets memory trace to cache_hit (3cc(find_data) + 1cc)

//Total --> hit = 10, miss = 2 
memory_trace = 0;//0000_0000_0000_0000 miss  
#210;
memory_trace = 9;//0000_0000_0000_1001 hit  
#210; 
memory_trace = 8;//0000_0000_0000_1000 hit 
#210; 
memory_trace = 1;//0000_0000_0000_0001 hit 
#210;
memory_trace = 4;//0000_0000_0000_0100 hit 
#210;
memory_trace = 5;//0000_0000_0000_0101 hit
#210;
memory_trace = 10;//0000_0000_0000_1010 hit
#210;
memory_trace = 4;//0000_0000_0000_0100 hit
#210;
memory_trace = 12;//0000_0000_0000_1100 hit 
#210;
memory_trace = 16;//0000_0000_0001_0000 miss 
#210;
memory_trace = 13;//0000_0000_0000_1101 hit 
#210;
memory_trace = 18;//0000_0000_0001_0010 hit
*/

//block_offset_bit = 6 // 64 B 
//cache_miss --> 68cc from the point where it gets memory trace to cache_miss (67 (3(block ram)+64B)cc (request block) + 1 cc (to update in cache))
//cache_hit --> 4cc from the point where it gets memory trace to cache_hit (3cc(find_data) + 1cc)

//Total --> hit = 10, miss = 2 
memory_trace = 0;//0000_0000_0000_0000 miss  
#690;
memory_trace = 9;//0000_0000_0000_1001 hit  
#690; 
memory_trace = 8;//0000_0000_0000_1000 hit 
#690; 
memory_trace = 1;//0000_0000_0000_0001 hit 
#690;
memory_trace = 4;//0000_0000_0000_0100 hit 
#690;
memory_trace = 5;//0000_0000_0000_0101 hit
#690;
memory_trace = 55;//0000_0000_0000_1010 hit
#690;
memory_trace = 45;//0000_0000_0000_0100 hit
#690;
memory_trace = 64;//0000_0000_0000_1100 miss 
#690;
memory_trace = 68;//0000_0000_0001_0000 hit 
#690;
memory_trace = 70;//0000_0000_0000_1101 hit 
#690;
memory_trace = 10;//0000_0000_0001_0010 hit

end

always #5 clk = ~ clk;
initial #8280 $finish; 

endmodule
