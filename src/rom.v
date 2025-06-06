// PDP-11 FPGA Core
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2025 by Michael Kohn

// This is a hardcoded program that blinks an external LED.

module rom
(
  input [11:0] address,
  input [15:0] data_in,
  output reg [15:0] data_out,
  input [1:0] write_mask,
  input write_enable,
  input clk
);

reg [15:0] memory [2047:0];

initial begin
  $readmemh("rom.txt", memory);
end

wire [10:0] aligned_address;
assign aligned_address = address[11:1];

always @(posedge clk) begin
  if (write_enable) begin
    //if (!write_mask[0]) storage_0[aligned_address] <= data_in[7:0];
    //if (!write_mask[1]) storage_1[aligned_address] <= data_in[15:8];
    if (!write_mask[0]) memory[aligned_address][7:0]  <= data_in[7:0];
    if (!write_mask[1]) memory[aligned_address][15:8] <= data_in[15:8];
  end else begin
    //data_out[7:0]   <= storage_0[aligned_address];
    //data_out[15:8]  <= storage_1[aligned_address];
    data_out <= memory[address[11:1]];
  end
end

endmodule

