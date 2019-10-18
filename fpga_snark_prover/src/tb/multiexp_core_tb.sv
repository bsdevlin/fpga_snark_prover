/*
  Testbench for the multiexp core.

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

module multiexp_core_tb ();
import bn128_pkg::*;

localparam CLK_PERIOD = 100;

logic clk, rst;

if_axi_stream #(.DAT_BYTS(256*3/8)) in_if(clk);
if_axi_stream #(.DAT_BYTS(256*3/8)) out_if(clk);

if_axi_stream #(.DAT_BYTS(256*2/8), .CTL_BITS(16)) mult_in_if(clk);
if_axi_stream #(.DAT_BYTS(256/8), .CTL_BITS(16)) mult_out_if(clk);

jb_point_t in_p, out_p;
logic [255:0] k_in;


initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end




initial begin
  jb_point_t out_p;
  jb_point_t in_p [];
  logic [DAT_BITS-1:0] in_s [];

  out_if.rdy = 0;
  in_if.val = 0;
  #(40*CLK_PERIOD);

  in_s = new[2];
  in_s[0] = 256'd2;
  in_s[1] = 256'd2;

  in_p = new[2];
  in_p[0] = G1_JB;
  in_p[1] = G1_JB;

  out_p = multiexp_batch(in_s,in_p);

  print_fp2_af_point(to_affine(out_p));

  #1us $finish();
end
endmodule