`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:10:46 07/29/2021 
// Design Name: 
// Module Name:    top_module_tb 
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
module top_module_tb(
  );
  
  wire [7:0] data_out;
  reg [7:0] data_in;
  reg sys_clk, sys_rst, sync_in;

  initial begin
    sys_clk = 1'b0;
    sys_rst = 1'b0;
    sync_in = 1'b0;
    data_in = 8'h00;

    sys_rst =  #50 1'b1;


    // mov v0, 0x0f0f
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    data_in = #200 8'h00; //8'hf8;
    sync_in = #200 ~sync_in;

    data_in = #200 8'h00; //8'h78;
    sync_in = #200 ~sync_in;


    data_in = #200 8'h00; //8'h40;
    sync_in = #200 ~sync_in;

    data_in = #200 8'h00; //8'h00;
    sync_in = #200 ~sync_in;
    sync_in = #100 0;

    // add v0, v0
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    data_in = #200 8'h00;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00; //8'h01;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00; //8'h80;
    sync_in = #200  ~sync_in;
    sync_in = #100 0;

    // mov v2, acc
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    sync_in = #400 ~sync_in;
    data_in = #200 8'h00;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00; //8'h05;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00; //8'h58;
    sync_in = #200  ~sync_in;

    data_in = #200 8'h00;
    sync_in = #200  ~sync_in;
    sync_in = #100 0;
  end




  always sys_clk = #50 ~sys_clk;


  top_module UUT(
    sys_clk, sys_rst, sync_in,
    data_in,
    sync_out,
    data_out
    );


endmodule
