`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:11:36 06/30/2021 
// Design Name: 
// Module Name:    top_module 
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
module top_module(
  input clk, nrst, sync_in,
  input [7:0] data_in,

  output sync_out,
  output [7:0] data_out,
  output reg [7:0] oled
  );

  wire [23:0] cpu_addr;
  wire [15:0] cpu_data, data_out_cpu;
  assign rst = ~nrst;
  
  always @(posedge clk) begin
    oled <= data_out;
  end

  IO io(
    clk, rst, 
    sync_in,
    data_in,

    cpu_load, cpu_store, 
    cpu_code_seg, cpu_data_seg, cpu_stack_seg, cpu_awb,
    cpu_addr,
    cpu_data,
    
    sync_out,
    data_out,
    
    ready_cpu,
    data_out_cpu
    );

  CPU cpu(
    clk, rst, ready_cpu,
    data_out_cpu,

    cpu_load, cpu_store, 
    cpu_code_seg, cpu_data_seg, cpu_stack_seg, cpu_awb,
    cpu_addr,
    cpu_data
    );


endmodule
