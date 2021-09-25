`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:33:56 07/26/2021 
// Design Name: 
// Module Name:    CPU_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module CPU_tb(
  );

  reg sys_clk, sys_rst, ready;
  wire load, store, code_seg, data_seg, stack_seg;
  reg [15:0] data_in; 
  wire [15:0] data_out;
  wire [23:0] addr_out;

  initial begin
    sys_clk = 1'b0;
    sys_rst = 1'b1;
    ready = 1'b0;
    sys_rst = #500 1'b0;

    // mov v0, 0x0f0f
    data_in = #750 16'hf878;
    ready = #750 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;

    data_in = #250 16'h4000;
    ready = #250 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;

    // add v0, v0
    data_in = #750 16'h0000;
    ready = #750 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;

    data_in = #250 16'h0180;
    ready = #250 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;  

    // mov v2, acc
    data_in = #750 16'h0005;
    ready = #750 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;

    data_in = #250 16'h5800;
    ready = #250 1'b1;
    ready = #75 1'b0;
    ready = #25 1'b0;  


  end
  
  always sys_clk = #50 ~sys_clk; 


CPU UUT(
  sys_clk, sys_rst, ready,
  data_in,

  load, store, 
  code_seg, data_seg, stack_seg,
  addr_out,
  data_out
  );

endmodule
