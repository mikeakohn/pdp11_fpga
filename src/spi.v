// PDP-11 FPGA Core
//  Author: Michael Kohn
//   Email: mike@mikekohn.net
//     Web: https://www.mikekohn.net/
//   Board: iceFUN iCE40 HX8K
// License: MIT
//
// Copyright 2025 by Michael Kohn

module spi
(
  input  raw_clk,
  input  start,
  //input  width_16,
  input  [7:0] data_tx,
  output [7:0] data_rx,
  output busy,
  output reg sclk,
  output reg mosi,
  input  miso
);

reg [1:0] state = 0;
reg [7:0] rx_buffer;
reg [7:0] tx_buffer;
reg [4:0] count;

assign data_rx = rx_buffer;
assign busy = state != STATE_IDLE;

parameter STATE_IDLE    = 0;
parameter STATE_CLOCK_0 = 1;
parameter STATE_CLOCK_1 = 2;
parameter STATE_LAST    = 3;

always @(posedge raw_clk) begin
  case (state)
    STATE_IDLE:
      begin
        if (start) begin
          tx_buffer <= data_tx;

          state <= STATE_CLOCK_0;
          count <= 0;
        end else begin
          mosi <= 0;
        end
      end
    STATE_CLOCK_0:
      begin
        sclk <= 0;

        if (count != 0) rx_buffer <= { rx_buffer[6:0], miso };

        tx_buffer <= tx_buffer << 1;
        mosi <= tx_buffer[7];

        count <= count + 1;
        state <= STATE_CLOCK_1;
      end
    STATE_CLOCK_1:
      begin
        sclk <= 1;

        if (count[3]) begin
          state <= STATE_LAST;
        end else begin
          state <= STATE_CLOCK_0;
        end
      end
    STATE_LAST:
      begin
        sclk <= 0;
        rx_buffer <= { rx_buffer[6:0], miso };
        state <= STATE_IDLE;
      end
  endcase
end

endmodule

