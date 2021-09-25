`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:06:44 07/02/2021 
// Design Name: 
// Module Name:    CPU 
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
module CPU(
  input clk, rst, ready,
  input [15:0] data_in,

  output reg load, store, 
  output code_seg, data_seg, stack_seg, alu_wb,
  output [23:0] addr_out,
  output [15:0] data_out
  );

  reg [15:0] IR [1:0]; // Instruction Register (High, Low)
  reg [4:0] flags; // 4:CF 3:ZF 2:SF 1:VF 0:HCF
  reg [3:0] main_state; // 3:IRH Wait 2:IRL Wait 1:Execution Wait 0:Execution

  wire [15:0] alu_Ai, alu_Bi, alu_Qo, imm_value, mem_data, PC, V2, ACC;
  wire [7:0] CS, DS, SS;
  wire [5:0] alu_opc;
  wire [4:0] pcpos;
  wire [2:0] isrc, idst, iscra;
  wire [1:0] iscrb;
  wire load_store_signal, new_carry_flag;

  ALU alu(
    alu_Ai, alu_Bi,
    alu_opc, // 5:ALU2 4:ALU1 3:ALU0 2:ARG1 1:ARG0 0:FUNC 
    alu_wb, alu_CFi,

    alu_Qo,
    CF, ZF, SF, VF, HCF, ALU_en
  );

  REGU regu(
    clk, rst, execution_signal,
    alu_Qo, imm_value, mem_data,
    pcpos,
    isrc, idst,
    twb,   
    tgpr_dst, titr_dst, tss_dst, tds_dst, tcs_dst, 
    tgpr_src, titr_src, imm_src, tss_src, tds_src, tcs_src, mem_src,
    iscra,
    iscrb,
    ALU_en, alu_wb, 

    alu_Ai, alu_Bi, PC, V2, ACC,
    CS, DS, SS
  );

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      IR[1] <= 16'h0; IR[0] <= 16'h0;
      main_state <= 4'b0100; // to load IRH
      load <= 1'b0;
      store <= 1'b0;
    end
    else begin
      if (main_state == 4'b0001) begin // EXECUCTION
        main_state <= 4'b0100; // to load IRH
      end
      
      else if (main_state == 4'b0010) begin // WAIT AND EXECUTION
        if (ready) begin
          main_state <= 4'b0100; // to load IRH
          load <= 1'b0;
          store <= 1'b0;
        end
        else begin
          if (load_store_signal) begin 
            if (IR[0][7]) store <= 1'b1;
            else load <= 1'b1;
          end
        end
      end

      else if (main_state == 4'b0100) begin // LOAD IRH
        if (ready && load) begin
          IR[1] <= data_in;
          main_state <= 4'b1000; // to load IRL
        end 
        else begin
          load <= 1'b1;
        end
      end

      else if (main_state == 4'b1000) begin // LOAD IRL
        if (ready && load) begin
          IR[0] <= data_in;                
          load <= 1'b0;
          if (IR[1][15:14] == 2'b01 && data_in[8]) begin
            main_state <= 4'b0010; // to wait and exec.
          end
          else begin
            main_state <= 4'b0001; // to exec.
          end
        end
      end
    end
  end

  // in/out data
  // assign loadir = &(main_state ^ 4'b1011);
  // assign addr_out = loadir ? { CS, PC } : { (IR[0][6] ? SS : DS), ACC };
  // assign data_out = V2;




  // instruction decoder (bits 31, 30 and 0)
  // 00x - POS, TRANSFER, ALU
  // 010 - POS, TRANSFER, CTRL
  // 011 - IMM, CTRL 
  // 1xx - IMM, ALU
  buf (bIR0,  IR[0][0]);
  buf (bIR30, IR[1][14]);
  buf (bIR31, IR[1][15]);
  not (nIR0,  IR[0][0]);
  not (nIR30, IR[1][14]);
  not (nIR31, IR[1][15]);  

  and (poso1, nIR31, nIR30);
  and (ctrlo, nIR31, bIR30);
  and (poso2, ctrlo, nIR0);
  and (immo1, ctrlo, bIR0);
  or (poso, poso1, poso2);
  or (immo, bIR31, immo1);
  or (aluo, bIR31, poso1);

  assign ctrl_oper = 
  (main_state[1:0] == 2'h1) | (ready && (main_state[1:0] == 2'h2)) ? ctrlo : 1'b0;

  assign alu_oper = 
  (main_state[1:0] == 2'h1) | (ready && (main_state[1:0] == 2'h2)) ? aluo : 1'b0;

  assign pstr_oper = 
  (main_state[1:0] == 2'h1) | (ready && (main_state[1:0] == 2'h2)) ? poso : 1'b0;

  assign imm_oper = 
  (main_state[1:0] == 2'h1) | (ready && (main_state[1:0] == 2'h2)) ? immo : 1'b0;


  // IR decoder
  // flags
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      flags <= 5'b00000;
    end
    else if (execution_signal) begin
      if (ALU_en) begin
        flags <= {CF, ZF, SF, VF, HCF};
      end
      else if (ctrl_oper) begin
        flags[4] <= new_carry_flag;
      end
    end
  end

  // 000N - HCF
  // 001N - CF
  // 010N - ZF
  // 011N - CF or ZF
  // 100N - SF
  // 101N - VF
  // 110N - SF xor VF
  // 111N - (SF xor VF) or ZF
  wire [3:0] ir_flags;
  assign ir_flags = IR[1][7:4];
  assign hc_temp  = flags[0] & (~ir_flags[3]) & (~ir_flags[2]) & (~ir_flags[1]); 
  assign c_temp   = flags[4] & (~ir_flags[3]) & ir_flags[1];
  assign z_temp1  = flags[3] & (~ir_flags[3]) & ir_flags[2];
  assign s_temp   = flags[2] & ir_flags[3]    & (~ir_flags[2]) & (~ir_flags[1]);
  assign v_temp   = flags[1] & ir_flags[3]    & (~ir_flags[2]) & ir_flags[1];
  assign ls_temp  = (flags[1] ^ flags[2])     & ir_flags[3]    & ir_flags[2];
  assign z_temp2  = flags[3] & ir_flags[3]    & ir_flags[2]    & ir_flags[1];

  assign branch_signal = ir_flags[0] ^ (hc_temp | c_temp | z_temp1 | v_temp |
                                        s_temp | c_temp | ls_temp | z_temp2);

  // pos
  assign pcpos = ((branch_signal | (~IR[1][13])) & pstr_oper) ? IR[1][12:8] : 5'h0;

  // transfer
  assign bit_D = IR[1][3];
  assign bit_18 = IR[1][2];
  assign bit_14 = IR[0][14];
  assign twb = IR[0][10];

  assign isrc = bit_D ? {IR[1][1:0], IR[0][15]} : IR[0][13:11];
  assign idst = bit_D ? IR[0][13:11] : {IR[1][1:0], IR[0][15]} ;
  assign tgpr_src = ({pstr_oper, bit_D, bit_14} == 3'b100) ? 1'b1 : 1'b0;
  assign titr_src = ({pstr_oper, bit_D, bit_18} == 3'b111 ||
                     {pstr_oper, bit_D, bit_14} == 3'b101) ? 1'b1 : 1'b0;
  assign tcs_src  = ({pstr_oper, bit_D, bit_18, IR[1][1:0], IR[0][15]} == 6'b110100) ? 1'b1 : 1'b0;
  assign tds_src  = ({pstr_oper, bit_D, bit_18, IR[1][1:0], IR[0][15]} == 6'b110010) ? 1'b1 : 1'b0;
  assign tss_src  = ({pstr_oper, bit_D, bit_18, IR[1][1:0], IR[0][15]} == 6'b110001) ? 1'b1 : 1'b0;
  assign tgpr_dst = ({pstr_oper, imm_oper, bit_14} == 3'b010 ||
                     {pstr_oper, bit_D, bit_14}    == 3'b110) ? 1'b1 : 1'b0;
  assign titr_dst = ({pstr_oper, imm_oper, bit_14} == 3'b011 ||
                     {pstr_oper, bit_D, bit_14}    == 3'b111 ||
                     {pstr_oper, bit_D, bit_18}    == 3'b101) ? 1'b1 : 1'b0;
  assign tcs_dst  = ({pstr_oper, imm_oper, IR[1][1], twb} == 4'b0111 ||
                     {pstr_oper, bit_D, bit_18, IR[1][1]} == 4'b1001) ? 1'b1 : 1'b0;
  assign tds_dst  = ({pstr_oper, imm_oper, IR[1][1], twb} == 4'b0111 ||
                     {pstr_oper, bit_D, bit_18, IR[1][0]} == 4'b1001) ? 1'b1 : 1'b0;
  assign tss_dst  = ({pstr_oper, imm_oper, IR[1][1], twb} == 4'b0111 ||
                    {pstr_oper, bit_D, bit_18, IR[0][15]} == 4'b1001) ? 1'b1 : 1'b0;


  // imm
  assign imm_src = imm_oper;
  assign imm_value = {twb ? 8'h00 : {IR[1][6:0], IR[0][15]}, 
                      alu_oper ? IR[1][14] : IR[0][5], IR[1][13:7]};

  // alu
  assign alu_opc = alu_oper ? {IR[0][8:6], IR[0][2:0]} : 6'h0;
  assign iscra = IR[0][5:3];
  assign iscrb = IR[0][2:1];
  assign alu_wb = IR[0][9];
  assign alu_CFi = flags[4];

  // ctrl
  // memory
  assign load_store_signal = (ctrl_oper & IR[0][8]) ? IR[0][7] : 1'b0;
  assign code_seg = main_state[3:2] != 2'b00;
  assign data_seg = load_store_signal & (~IR[0][6]);
  assign stack_seg = load_store_signal & IR[0][6];
  assign addr_out = {stack_seg ? SS : code_seg ? CS : DS, code_seg ? PC : ACC};
  assign data_out = V2;
  assign mem_data = data_in;
  assign mem_src = main_state[1] & ready;

  assign execution_signal = main_state[0] | mem_src;
  assign new_carry_flag = IR[0][4] ? IR[0][3] : flags[4] ^ IR[0][3];

endmodule
