/*
  Copyright (C) 2019  Benjamin Devlin

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/
`timescale 1ps/1ps
`define SIMULATION

module montgomery_mult_tb ();
import common_pkg::*;
import bn128_pkg::*;

localparam CLK_PERIOD = 100;

logic clk, rst;

parameter BITS = 256;
parameter A_DSP_W = 26;
parameter B_DSP_W = 17;
parameter CTL_BITS = 8;

// This is the max size we can expect on the output
if_axi_stream #(.DAT_BYTS((2*BITS+7)/8), .CTL_BITS(8)) in_if(clk);
if_axi_stream #(.DAT_BYTS((BITS+7)/8), .CTL_BITS(8)) out_if(clk);

initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #CLK_PERIOD clk = ~clk;
end

// Check for errors
always_ff @ (posedge clk)
  if (out_if.val && out_if.err)
    $error(1, "%m %t ERROR: output .err asserted", $time);

montgomery_mult_wrapper #(
  .DAT_BITS    ( DAT_BITS         ),
  .CTL_BITS    ( CTL_BITS         ),
  .REDUCE_BITS ( MONT_REDUCE_BITS ),
  .FACTOR      ( MONT_FACTOR      ),
  .MASK        ( MONT_MASK        ),
  .P           ( P                ),
  .A_DSP_W     ( A_DSP_W          ),
  .B_DSP_W     ( B_DSP_W          )
)
montgomery_mult_wrapper (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_mont_mul_if ( in_if  ),
  .o_mont_mul_if ( out_if )
);

task test_loop();
begin
  integer signed get_len;
  logic [common_pkg::MAX_SIM_BYTS*8-1:0] get_dat;
  logic [BITS-1:0] in_a, in_b, expected;
  logic [BITS*2-1:0] out;
  integer t;
  integer i, max;

  $display("Running test_loop...");
  i = 0;
  max = 1000;

  while (i < max) begin
    in_a = random_vector((BITS+7)/8) % P;
    in_b = random_vector((BITS+7)/8) % P;
    expected = fe_mul_mont(in_a, in_b);

    fork
      in_if.put_stream({in_b, in_a}, ((BITS*2)+7)/8, i);
      out_if.get_stream(get_dat, get_len, 0);
    join

    out = get_dat;

    assert(out == expected) else begin
      $display("Expected: 0x%0x", expected);
      $display("Was:      0x%0x", out);
      $fatal(1, "ERROR: Output did not match");
    end
    $display("test_loop PASSED loop %0d/%0d - 0x%0x", i, max, out);
    i = i + 1;
  end

  $display("test_loop PASSED");
end
endtask;

initial begin
  out_if.rdy = 0;
  in_if.reset_source();
  #(40*CLK_PERIOD);

  test_loop();

  #1us $finish();
end
endmodule