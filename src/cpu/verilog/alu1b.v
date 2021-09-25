`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:30:52 06/30/2021 
// Design Name: 
// Module Name:    alu1b 
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
module alu1b(
  input [8:0] ctrl, // 8:B 7:NOTB 6:SHIFTR 5:SHIFTL 4:NOR 3:OR 2:AND 1:SUM 0:XOR
  input a, b, ci, ri,
  output q, co, ro
  );

  // not b
  and (and_b, b, ctrl[8]);
  xor (nb, and_b, ctrl[7]);

  // adder
  xor (xor_ab, nb, a);
  xor (sum_ab, xor_ab, ci);
  and (and_ab, nb, a);
  and (and_xabc, xor_ab, ci);
  or (co_ab, and_xabc, and_ab);

  // ADD/SUB
  and (qsum, sum_ab, ctrl[1]);
  and (csum, co_ab, ctrl[1]);

  // XOR
  and (qxor, xor_ab, ctrl[0]);

  // OR/NOR
  or (or_ab, nb, a);
  and (qor, or_ab, ctrl[3]);
  nor (nor_ab, nb, a);
  and (qnor, nor_ab, ctrl[4]);

  // AND
  and (qand, and_ab, ctrl[2]);
  
  // SHIFTL
  and (cshl, a, ctrl[5]);
  and (qshl, ci, ctrl[5]);

  // SHIFTR
  and (qshr, ri, ctrl[6]);  

  // qout
  or (q, qxor, qsum, qand, qor, qnor, qshl, qshr);

  // cout
  or (co, csum, cshl);
  
  // rout
  buf (ro, a);



endmodule
