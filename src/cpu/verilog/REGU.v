`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:55:55 07/02/2021 
// Design Name: 
// Module Name:    REGU 
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
module REGU(
  input clk, rst, execution_signal,
  input [15:0] alu_Q, imm_value, mem_data,
  input [4:0] pcpos,
  input [2:0] isrc, idst,
  input twb, 
  tgpr_dst, titr_dst, tss_dst, tds_dst, tcs_dst, 
  tgpr_src, titr_src, imm_src, tss_src, tds_src, tcs_src, mem_src,
  input [2:0] iscra,
  input [1:0] iscrb,
  input ALU_en, awb, 

  output [15:0] out_A, out_B, // to ALU
                PC, V2, ACC,    
  output reg [7:0] CS, DS, SS

  );
  
  wire [15:0] main_bus;
  // treg - 0:V0 1:V1 2:V2 3:ACC idx - 4:IX 5:IY 6:SP 7:PC
  reg [7:0] lo_ITR [7:0];
  reg [7:0] hi_ITR [7:0];

  // 0:R0 1:R1 2:R2 3:R3 4:R4 5:R5 6:R6 7:R7
  reg [7:0] lo_GPR [7:0];
  reg [7:0] hi_GPR [7:0];

  // REGISTER <= main_bus
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      lo_ITR[0] <= 8'h00; hi_ITR[0] <= 8'h00; // V0
      lo_ITR[1] <= 8'h00; hi_ITR[1] <= 8'h00; // V1
      lo_ITR[2] <= 8'h00; hi_ITR[2] <= 8'h00; // V2
      lo_ITR[3] <= 8'h00; hi_ITR[3] <= 8'h00; // ACC
      lo_ITR[4] <= 8'h00; hi_ITR[4] <= 8'h00; // IX
      lo_ITR[5] <= 8'h00; hi_ITR[5] <= 8'h00; // IY
      lo_ITR[6] <= 8'h00; hi_ITR[6] <= 8'h00; // SP
      lo_ITR[7] <= 8'h00; hi_ITR[7] <= 8'h00; // PC

      lo_GPR[0] <= 8'h00; hi_GPR[0] <= 8'h00; // R0
      lo_GPR[1] <= 8'h00; hi_GPR[1] <= 8'h00; // R1
      lo_GPR[2] <= 8'h00; hi_GPR[2] <= 8'h00; // R2
      lo_GPR[3] <= 8'h00; hi_GPR[3] <= 8'h00; // R3
      lo_GPR[4] <= 8'h00; hi_GPR[4] <= 8'h00; // R4
      lo_GPR[5] <= 8'h00; hi_GPR[5] <= 8'h00; // R5
      lo_GPR[6] <= 8'h00; hi_GPR[6] <= 8'h00; // R6
      lo_GPR[7] <= 8'h00; hi_GPR[7] <= 8'h00; // R7

      CS <= 8'hff;
      DS <= 8'hff;
      SS <= 8'hff;
    end
    else if (execution_signal) begin
      // increment PC
      if (idst != 3'h7) begin
        // PC += pos OR PC -= pos
        {hi_ITR[7], lo_ITR[7]} <= {hi_ITR[7], lo_ITR[7]} + 
          {pcpos[4] ? 10'h3ff : 10'h0, pcpos[3:0], 2'b00} + 3'h4;
      end
      
      if (titr_dst) begin // TREG/IDX <= main_bus
        lo_ITR[idst] <= main_bus[7:0];
        if (!twb) begin
          hi_ITR[idst] <= main_bus[15:8];
        end
      end

      else if (tgpr_dst) begin // GPR <= main_bus
        lo_GPR[idst] <= main_bus[7:0];
        if (!twb) begin
          hi_GPR[idst] <= main_bus[15:8];
        end
      end

      else begin // SEG <= main_bus
        if (tss_dst) SS <= main_bus[7:0];
        if (tds_dst) DS <= main_bus[7:0];
        if (tcs_dst) CS <= main_bus[7:0];
      end

      if (ALU_en) begin // ACC <= alu_result
        lo_ITR[3] <= alu_Q[7:0];
        if (!awb) begin
          hi_ITR[3] <= alu_Q[15:8];
        end
      end

      // V2 <= load_from_memory
      if (mem_src) begin
        lo_ITR[2] <= mem_data[7:0];
        if (!awb) begin
          hi_ITR[2] <= mem_data[15:8];
        end
      end
    end
  end

  // main_bus <= REGISTER
  assign main_bus = titr_src ? { hi_ITR[isrc], lo_ITR[isrc] } : 16'hz;
  assign main_bus = tgpr_src ? { hi_GPR[isrc], lo_GPR[isrc] } : 16'hz;
  assign main_bus = imm_src  ? imm_value : 16'hz;
  assign main_bus = tss_src  ? { 8'h00, SS } : 16'hz;
  assign main_bus = tds_src  ? { 8'h00, DS } : 16'hz;
  assign main_bus = tcs_src  ? { 8'h00, CS } : 16'hz;

  // alu_bus <= REGISTER
  assign out_A = { hi_ITR[iscra], lo_ITR[iscra] };
  assign out_B = { hi_ITR[iscrb], lo_ITR[iscrb] };


  assign PC = {hi_ITR[7], lo_ITR[7]}; 
  assign V2 = {hi_ITR[2], lo_ITR[2]};
  assign ACC = {hi_ITR[3], lo_ITR[3]};

endmodule
