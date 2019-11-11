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


if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) mul_o_if [3:0] (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) mul_i_if [3:0] (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*4), .CTL_BITS(CTL_BITS)) add_o_if (clk);
if_axi_stream #(.DAT_BITS(1+DAT_BITS*2), .CTL_BITS(CTL_BITS)) add_i_if (clk);

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


always_comb add_o_if.rdy = (add_i_if.rdy && add_i_if.val) || (~add_i_if.val);

always_ff @ (posedge clk) begin
  if (rst) begin
    add_i_if.reset_source();
  end else begin
    if (add_i_if.rdy) add_i_if.val <= 0;
  
    add_i_if.sop <= 1;
    add_i_if.eop <= 1;
    if (add_o_if.rdy) begin
      add_i_if.dat <= add_o_if.dat[0 +: 2*DAT_BITS] + add_o_if.dat[2*DAT_BITS +: 2*DAT_BITS];
      add_i_if.val <= add_o_if.val;
      add_i_if.ctl <= add_o_if.ctl;
    end
  end
end

montgomery_mult #(
  .DAT_BITS    ( DAT_BITS         ),
  .CTL_BITS    ( CTL_BITS         ),
  .REDUCE_BITS ( MONT_REDUCE_BITS ),
  .FACTOR      ( MONT_FACTOR      ),
  .MASK        ( MONT_MASK        ),
  .P           ( P                )
)
montgomery_mult (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_mont_mul_if ( in_if  ),
  .o_mont_mul_if ( out_if ),
  .o_mul_if_0 ( mul_o_if[0] ),
  .i_mul_if_0 ( mul_i_if[0] ),
  .o_mul_if_1 ( mul_o_if[1] ),
  .i_mul_if_1 ( mul_i_if[1] ),
  .o_mul_if_2 ( mul_o_if[2] ),
  .i_mul_if_2 ( mul_i_if[2] ),
  .o_add_if ( add_o_if ),
  .i_add_if ( add_i_if )
);

adder_pipe # (
  .P   ( 512'd0 ) ,
  .BITS( 512    ),
  .CTL_BITS( CTL_BITS ),
  .LEVEL( 3 )
) 
adder_pipe (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_add ( add_o_if ),
  .o_add ( add_i_if )
);

resource_share # (
  .NUM_IN       ( 3          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 4          ),
  .PIPELINE_IN  ( 1          ),
  .PIPELINE_OUT ( 1          )
)
resource_share_mul (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_axi ( mul_o_if[2:0] ),
  .o_res ( mul_o_if[3]   ),
  .i_res ( mul_i_if[3]   ),
  .o_axi ( mul_i_if[2:0] )
);

multiplier #(
  .DAT_BITS ( BITS     ),
  .CTL_BITS ( CTL_BITS ),
  .A_DSP_W  ( A_DSP_W  ),
  .B_DSP_W  ( B_DSP_W  )
)
multiplier (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_mul ( mul_o_if[3] ),
  .o_mul ( mul_i_if[3] )
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