`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2020 10:51:43
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

    reg clk,trace_ready;
    reg [31:0] mem_addr;
    
    wire updated;
    wire [19:0] cache_hit_count,cache_miss_count;
    
    integer binary_file;
    integer scan_file;
         
    main uut (clk,trace_ready,mem_addr,updated,cache_hit_count,cache_miss_count);
    
    initial
    begin        
        clk = 1'b0;
        binary_file = $fopen("/home/shivani/Documents/SEM2/Research/project/Simulation_input_files/twolf_binary.dat","r");
        scan_file = $fscanf(binary_file, "%b\n", mem_addr); 
        trace_ready = 1'b1;
        
        #10;  trace_ready = 1'b0;    
    end
    
    always @ (posedge clk)
    begin
        if (updated)
        begin    
            scan_file = $fscanf(binary_file, "%b\n", mem_addr);
            #10; trace_ready = 1'b1;
            #10; trace_ready = 1'b0;
        end     
    end
    
    always #5 clk = ~ clk;
    initial #5000000 $finish; 
    
endmodule