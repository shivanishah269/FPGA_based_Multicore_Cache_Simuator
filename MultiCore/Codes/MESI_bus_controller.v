`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.08.2021 11:29:30
// Design Name: 
// Module Name: MESI_bus_controller
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


module MESI_bus_controller(core_id,copy,ins_type,L1_found_in_cache_core0,L1_found_in_cache_core1,L1_found_in_cache_core2,L1_found_in_cache_core3,bus_signals);
    
    input [1:0] core_id;
    input copy; // copy - 0 if it is single copy else 1 for more than one copy
    input ins_type,L1_found_in_cache_core0,L1_found_in_cache_core1,L1_found_in_cache_core2,L1_found_in_cache_core3;
    
    output  [4:0] bus_signals; // {core_id, BusRd, BusRdX, BusUpgr} 
            
    // read-write hit-miss, 
    // read_miss - 00, read_hit - 01, write_miss - 10 & write_hit - 11
    wire [1:0] rw_hm;
    
    assign rw_hm = (core_id == 0) ?  {ins_type,L1_found_in_cache_core0} :
                   (core_id == 1) ?  {ins_type,L1_found_in_cache_core1} :
                   (core_id == 2) ?  {ins_type,L1_found_in_cache_core2} : 
                   (core_id == 3) ?  {ins_type,L1_found_in_cache_core3} : 2'b00;

    assign bus_signals = {core_id,
                          ((rw_hm == 2'b00) && copy) ? 3'b100 : 
                          (rw_hm == 2'b10) ? 3'b010 :
                          ((rw_hm == 2'b11) && copy) ? 3'b001 : 3'b000}; 
                                              
endmodule