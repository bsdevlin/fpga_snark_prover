/*
  Testbench for the G2 multiexp core.

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

module multiexp_fp2_core_tb ();
import bn128_pkg::*;
import common_pkg::*;

localparam CLK_PERIOD = 100;

localparam NUM_IN = 1;
localparam DAT_BITS = $bits(fe_t);
localparam KEY_BITS = $bits(P);
localparam CTL_BITS = 9;

logic clk, rst;

fp2_jb_point_t res_o;
always_comb res_o = o_pnt_if.dat;

if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) mul_o_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) mul_i_if (clk);

localparam DAT_IN0 = $bits(fe_t) + $bits(fp2_jb_point_t);

if_axi_stream #(.DAT_BYTS(($bits(fe_t)+7)/8), .CTL_BITS(CTL_BITS)) i_pnt_scl_if (clk);
if_axi_stream #(.DAT_BYTS(($bits(fe_t)+7)/8), .CTL_BITS(CTL_BITS)) o_pnt_if (clk);

fp2_jb_point_t in_p [];
fe_t in_s [];

logic [63:0] num_in;

logic [$clog2(DAT_BITS*NUM_IN):0] cnt;

initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

multiexp_fp2_core #(
  .FP_TYPE  ( jb_point_t ),
  .FE_TYPE  ( fe_t       ),
  .FP2_TYPE ( fp2_jb_point_t ),
  .FE2_TYPE ( fe2_t      ),  
  .KEY_BITS ( KEY_BITS   ),
  .CTL_BITS ( CTL_BITS   ),
  .CONST_3  ( CONST_3    ),
  .CONST_4  ( CONST_4    ),
  .CONST_8  ( CONST_8    ),
  .P        ( P          )
)
multiexp_fp2_core (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_pnt_scl_if ( i_pnt_scl_if ),
  .i_num_in ( num_in ),
  .o_pnt_if ( o_pnt_if ),
  .o_mul_if( mul_o_if ),
  .i_mul_if( mul_i_if )
);

montgomery_mult_wrapper #(
  .DAT_BITS    ( DAT_BITS         ),
  .CTL_BITS    ( CTL_BITS         ),
  .REDUCE_BITS ( MONT_REDUCE_BITS ),
  .FACTOR      ( MONT_FACTOR      ),
  .MASK        ( MONT_MASK        ),
  .P           ( P                ),
  .A_DSP_W     ( 27               ),
  .B_DSP_W     ( 17               )
)
montgomery_mult_wrapper (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_mont_mul_if ( mul_o_if  ),
  .o_mont_mul_if ( mul_i_if )
);


task test0();
begin
  integer signed get_len;
  logic [common_pkg::MAX_SIM_BYTS*8-1:0] get_dat;
  fp2_jb_point_t out;
  fp2_af_point_t expected;
  fe_t new_s;
  cnt = DAT_BITS-1;
  
  in_p = new[NUM_IN];
  in_s = new[NUM_IN];
  num_in = NUM_IN;

  $display("Running test0...");

  for (int i = 0; i < NUM_IN; i++) begin
    in_p[i] = fp2_point_mult(random_vector((DAT_BITS+7)/8) % P, fp2_jb_to_mont(G2_JB));
    $display("Input point #%d", i);
    print_fp2_jb_point(in_p[i]);
    in_s[i] = random_vector((DAT_BITS+7)/8) % P;
    $display("Key 0x%x", in_s[i]);
  end
 
  expected = fp2_to_affine(fp2_jb_from_mont(fp2_multiexp_batch(in_s, in_p)), 0);

  fork
    for(int j = 0; j < DAT_BITS; j++) begin
      for (int i = 0; i < NUM_IN; i++) begin
        new_s = in_s[i] << j;
        i_pnt_scl_if.put_stream({in_p[i], new_s}, (DAT_IN0+7)/8, 0);
      end
      cnt--;
    end
    begin
      o_pnt_if.get_stream(get_dat, get_len, 0);
    end
  join

  out = get_dat;
  
  assert(fp2_to_affine(fp2_jb_from_mont(out), 0) == expected) else begin
    $display("Expected:");
    print_fp2_af_point(expected);
    $display("Was:");
    print_fp2_af_point(fp2_to_affine(fp2_jb_from_mont(out), 0));
    $fatal(1, "ERROR: Output did not match");
  end

  $display("test0 PASSED");
  in_p.delete();
  in_s.delete();
end
endtask;


initial begin
  num_in = 0;
  i_pnt_scl_if.reset_source();
  o_pnt_if.rdy = 0;
  
  #(100*CLK_PERIOD);

  test0();
  #1us $finish();
end
endmodule