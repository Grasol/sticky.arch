`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:52:49 06/30/2021 
// Design Name: 
// Module Name:    ALU 
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
module ALU(
  input [15:0] Ai, Bi,
  input [5:0] oper, // 5: ALU2 4: ALU1 3: ALU0 2: ARG1 1: ARG0 0: FUNC 
  input wb, CFi,
  output [15:0] Qo,
  output CF, ZF, SF, VF, HCF, ALU_en
  );

  // operation decoder
  wire [8:0] ctrl; // 8:B 7:NOTB 6:SHIFTR 5:SHIFTL 4:NOR 3:OR 2:AND 1:SUM 0:XOR

  not (nalu2, oper[5]);
  not (nalu1, oper[4]);
  not (nalu0, oper[3]);
  not (narg1, oper[2]);
  not (narg0, oper[1]);
  not (nfunc, oper[0]);

  and (xor_and_ctrl, oper[5], nalu1, nalu0);
  and (shift_ctrl, nalu2, nalu1, oper[3]);
  and (or_nor_ctrl, oper[5], nalu1, oper[3]);
  and (add_ctrl, oper[4], nalu0);
  and (notb_ctrl, oper[4], oper[3]);

  buf (ctrl[8], oper[5]);
  buf (ctrl[7], notb_ctrl);
  and (ctrl[6], oper[0], shift_ctrl);
  and (ctrl[5], nfunc,   shift_ctrl);
  and (ctrl[4], oper[0], or_nor_ctrl);
  and (ctrl[3], nfunc,   or_nor_ctrl);
  and (ctrl[2], oper[0], xor_and_ctrl);
  or  (ctrl[1], add_ctrl, notb_ctrl);
  and (ctrl[0], nfunc, xor_and_ctrl);

  or (ALU_en, oper[5], oper[4], oper[3]);

  // main
  alu1b u0(ctrl, Ai[0], Bi[0], carryi0, righti1,
           Qo0, carryo1, righto0);
  or (Qo[0], Qo0, ci0);
  buf (carryi1, carryo1); buf (righti1, righto1);
  alu1b u1(ctrl, Ai[1], Bi[1], carryi1, righti2,
           Qo[1], carryo2, righto1);
  
  buf (carryi2, carryo2); buf (righti2, righto2);  
  alu1b u2(ctrl, Ai[2], Bi[2], carryi2, righti3,
           Qo[2], carryo3, righto2);
  
  buf (carryi3, carryo3); buf (righti3, righto3);  
  alu1b u3(ctrl, Ai[3], Bi[3], carryi3, righti4,
           Qo[3], carryo4, righto3);
  
  buf (carryi4, carryo4); buf (righti4, righto4);  
  alu1b u4(ctrl, Ai[4], Bi[4], carryi4, righti5,
           Qo[4], carryo5, righto4);
  
  buf (carryi5, carryo5); buf (righti5, righto5);  
  alu1b u5(ctrl, Ai[5], Bi[5], carryi5, righti6,
           Qo[5], carryo6, righto5);
  
  buf (carryi6, carryo6); buf (righti6, righto6);  
  alu1b u6(ctrl, Ai[6], Bi[6], carryi6, righti7,
           Qo[6], carryo7, righto6);
  
  buf (carryi7, carryo7); buf (righti7, righto7);  
  alu1b u7(ctrl, Ai[7], Bi[7], carryi7, righti8,
           Qo[7], carryo8, righto7);
  
  buf (carryi8, carryo8); or (righti8, righto8, ri8);  
  alu1b u8(ctrl, Ai[8], Bi[8], carryi8, righti9,
           Qo[8], carryo9, righto8);
  
  buf (carryi9, carryo9); buf (righti9, righto9);  
  alu1b u9(ctrl, Ai[9], Bi[9], carryi9, righti10,
           Qo[9], carryo10, righto9);
  
  buf (carryi10, carryo10); buf (righti10, righto10);  
  alu1b u10(ctrl, Ai[10], Bi[10], carryi10, righti11,
           Qo[10], carryo11, righto10);
  
  buf (carryi11, carryo11); buf (righti11, righto11);  
  alu1b u11(ctrl, Ai[11], Bi[11], carryi11, righti12,
           Qo[11], carryo12, righto11);
  
  buf (carryi12, carryo12); buf (righti12, righto12);  
  alu1b u12(ctrl, Ai[12], Bi[12], carryi12, righti13,
           Qo[12], carryo13, righto12);
  
  buf (carryi13, carryo13); buf (righti13, righto13);  
  alu1b u13(ctrl, Ai[13], Bi[13], carryi13, righti14,
           Qo[13], carryo14, righto13);
  
  buf (carryi14, carryo14); buf (righti14, righto14);  
  alu1b u14(ctrl, Ai[14], Bi[14], carryi14, righti15,
           Qo[14], carryo15, righto14);
  
  buf (carryi15, carryo15); buf (righti15, righto15);  
  alu1b u15(ctrl, Ai[15], Bi[15], carryi15, righti16,
           Qo[15], carryo16, righto15);

  // flags
  // CF carry, ZF zero, SF sign, VF overflow, PF parity, HCF halfcarry
  assign CF = (notb_ctrl ^ (wb ? carryo8 : carryo16)) | 
              (righto0 & ctrl[6]);  // carry/borrow/shifts
  
  nor (lo_zero, Qo[0], Qo[1], Qo[2], Qo[3], Qo[4], Qo[5], Qo[6], Qo[7]);
  nor (hi_zero, Qo[8], Qo[9], Qo[10], Qo[11], Qo[12], Qo[13], Qo[14], Qo[15]);
  assign ZF = wb ? lo_zero : (lo_zero & hi_zero);

  assign SF = wb ? Qo[7] : Qo[15];

  assign VF = wb ? (carryo8 ^ carryo7) : (carryo16 ^ carryo15);

  buf (HCF, carryo4);

  // carryi/righti
  and (arth_shift, shift_ctrl, narg1, oper[1]); // 001.01.X
  and (rotate, shift_ctrl, oper[2], narg0); // 001.10.X
  and (cy_rotate, shift_ctrl, oper[2], oper[1]); // 001.11.X

  assign adc_sbb_rotc = notb_ctrl ^ (CFi & ((oper[0] & add_ctrl) | cy_rotate));
  assign sar = arth_shift & (wb ? Ai[7] : Ai[15]);
  assign rot = rotate & ((wb ? carryo8 : carryo16) | (righto0 & ctrl[6]));

  buf (carryi0, adc_sbb_rotc);

  not (nwb, wb);
  or (sar_rot, sar, rot);
  and (righti16, sar_rot, nwb, ctrl[6]);
  and (ri8, sar_rot, wb, ctrl[6]);
  and (ci0, rot, ctrl[5]);

endmodule
