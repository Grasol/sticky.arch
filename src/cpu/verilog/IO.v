`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:50:50 07/29/2021 
// Design Name: 
// Module Name:    IO 
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
module IO(
  input clk, rst, 
  input sync_in,
  input [7:0] data_in,

  input cpu_load, cpu_store, 
  input cpu_code_seg, cpu_data_seg, cpu_stack_seg, cpu_awb,
  input [23:0] cpu_addr,
  input [15:0] cpu_data,
  
  output reg sync_out,
  output reg [7:0] data_out,

  output reg ready_cpu,
  output reg [15:0] data_out_cpu
  );
  
  reg ready;
  reg [3:0] main_state;
  reg [7:0] header; // 7:LS 6:W 5:IL 4:r 3:r 2:CS 1:DS 0:SS 

  assign LS_bit = cpu_load ? 1'b0 : cpu_store ? 1'b1 : 1'b0;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      main_state <= 4'b0000;
      header <= 8'h00;
      sync_out <= 1'b0;
      data_out <= 8'h00;
      data_out_cpu <= 16'h0000;
      ready <= 1'b0;
    end
    else if ((sync_out == sync_in) || (main_state == 4'b1111)) begin
      if ((cpu_load || cpu_store)) begin
        case (main_state)
        4'b0000: begin
          header <= {LS_bit, cpu_awb, cpu_code_seg, 1'b0, 
                     1'b0, cpu_code_seg, cpu_data_seg, cpu_stack_seg};
          data_out <= {LS_bit, cpu_awb, cpu_code_seg, 1'b0, 
                     1'b0, cpu_code_seg, cpu_data_seg, cpu_stack_seg};
          sync_out <= ~sync_out;
          main_state <= 4'b0001;
        end
        4'b0001: begin // segment
          data_out <= cpu_addr[23:16]; 
          sync_out <= ~sync_out;
          main_state <= 4'b0010;
        end

        4'b0010: begin // address hi
          data_out <= cpu_addr[15:8]; 
          sync_out <= ~sync_out;
          main_state <= 4'b0011;
        end

        4'b0011: begin // address lo
          data_out <= cpu_addr[7:0]; 
          sync_out <= ~sync_out;
          if (header[5]) 
            main_state <= 4'b0100;
          else if (!header[7]) 
            main_state <= {3'b011, header[6]};
          else if (header[7])
            main_state <= {3'b110, header[6]};
        end

        4'b0100: begin // recv data hi-hi
          data_out_cpu[15:8] <= data_in; 
          sync_out <= ~sync_out;
          main_state <= 4'b0101;
        end

        4'b0101: begin // recv data hi-lo
          data_out_cpu[7:0] <= data_in; 
          sync_out <= ~sync_out;
          main_state <= 4'b0110;
          ready <= 1'b1;
        end

        4'b0110: begin // recv data lo-hi
          data_out_cpu[15:8] <= data_in;
          sync_out <= ~sync_out;
          main_state <= 4'b0111;
          ready <= 1'b0;
        end

        4'b0111: begin // recv data lo-lo
          data_out_cpu[7:0] <= data_in;
          sync_out <= ~sync_out;
          main_state <= 4'b1111;
          ready <= 1'b1;
        end

        4'b1100: begin // send data hi
          data_out <= cpu_data[15:8];
          sync_out <= ~sync_out;
          main_state <= 4'b1101;
        end

        4'b1101: begin // send data lo
          data_out <= cpu_data[7:0];
          sync_out <= ~sync_out;
          main_state <= 4'b1111;
          ready <= 1'b1;
        end

        4'b1111: begin
          main_state <= 4'b0000;
          ready <= 1'b0;
          sync_out <= 1'b0;
        end

        default: begin
          main_state <= 4'b0000;
          ready <= 1'b0;
        end
        endcase
      end
    end
    else begin
      ready <= 1'b0;
    end
  end
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      ready_cpu <= 1'b0;
    end
    else begin
      ready_cpu <= ((ready == 1) && (ready_cpu == 0)) ? 1'b1 : 1'b0;
    end
  end

endmodule
