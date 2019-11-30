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
import common_pkg::*;

localparam CLK_PERIOD = 100;

localparam NUM_IN = 2;
localparam DAT_BITS = $bits(fe_t);
localparam KEY_BITS = $bits(P);
localparam CTL_BITS = 8;

logic clk, rst;

jb_point_t res_o;
always_comb res_o = o_pnt_if.dat;

if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) mul_o_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) mul_i_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) add_o_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) add_i_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) sub_o_if (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) sub_i_if   (clk);

localparam DAT_IN0 = $bits(fe_t) + $bits(jb_point_t);
localparam DAT_IN1 = $bits(jb_point_t);

if_axi_stream #(.DAT_BYTS((DAT_IN0+7)/8), .CTL_BITS(CTL_BITS)) i_pnt_scl_if (clk);
if_axi_stream #(.DAT_BYTS((DAT_IN1+7)/8), .CTL_BITS(CTL_BITS)) o_pnt_if (clk);

jb_point_t in_p [];
fe_t in_s [];

initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

multiexp_core #(
  .FP_TYPE  ( jb_point_t ),
  .FE_TYPE  ( fe_t       ),
  .KEY_BITS ( KEY_BITS   ),
  .CTL_BITS ( CTL_BITS   ),
  .NUM_IN   ( NUM_IN     ),
  .CONST_3  ( CONST_3    ),
  .CONST_4  ( CONST_4    ),
  .CONST_8  ( CONST_8    )
)
multiexp_core (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_pnt_scl_if ( i_pnt_scl_if ),
  .o_pnt_if ( o_pnt_if ),
  .o_mul_if( mul_o_if ),
  .i_mul_if( mul_i_if ),
  .o_add_if( add_o_if ),
  .i_add_if( add_i_if ),
  .o_sub_if( sub_o_if ),
  .i_sub_if( sub_i_if )
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

adder_pipe # (
  .P       ( P        ) ,
  .BITS    ( DAT_BITS ),
  .CTL_BITS( CTL_BITS ),
  .LEVEL   ( 2        )
)
adder_pipe (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_add ( add_o_if ),
  .o_add ( add_i_if )
);

subtractor_pipe # (
  .P       ( P        ),
  .BITS    ( DAT_BITS ),
  .CTL_BITS( CTL_BITS ),
  .LEVEL   ( 2        )
)
subtractor_pipe (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_sub ( sub_o_if ),
  .o_sub ( sub_i_if )
);

task test0();
begin
  integer signed get_len;
  logic [common_pkg::MAX_SIM_BYTS*8-1:0] get_dat;
  jb_point_t out;
  af_point_t expected;
  
  in_p = new[NUM_IN];
  in_s = new[NUM_IN];

  $display("Running test0...");

  for (int i = 0; i < NUM_IN; i++) begin
    in_p[i] = jb_to_mont(point_mult(random_vector((DAT_BITS+7)/8) % P, G1_JB));
    in_s[i] = random_vector((DAT_BITS+7)/8) % P;
  end

  expected = to_affine(multiexp_batch(in_s, in_p));

  fork
    for(int j = 0; j < DAT_BITS; j++) begin
      for (int i = 0; i < NUM_IN; i++) i_pnt_scl_if.put_stream({in_p[i], in_s[i]}, (DAT_IN0+7)/8, i);
    end
    begin
      o_pnt_if.get_stream(get_dat, get_len, 0);
    end
  join

  out = get_dat;

  assert(to_affine(out) == expected) else begin
    $display("Expected: 0x%0x", expected);
    $display("Was:      0x%0x", to_affine(jb_from_mont(out)));
    $fatal(1, "ERROR: Output did not match");
  end


  $display("test0 PASSED");
  in_p.delete();
  in_s.delete();
end
endtask;


initial begin

  i_pnt_scl_if.reset_source();
  o_pnt_if.rdy = 0;
  
  #(100*CLK_PERIOD);

  test0();
  /*
  in_s = new[2];
  in_s[0] = 256'd2;
  in_s[1] = 256'd40;

  in_p = new[2];
  in_p[0] = G1_JB;
  in_p[1] = point_mult(256'd2, G1_JB);
  
   for (int i = 0; i < NUM_IN; i++) begin
    $display("Point %d", i);
    print_jb_point(in_p[i]);
    $display("Scalar %d 0x%x", i, in_s[i]);
  end
  
  multiexp_batch(in_s, in_p);
  jb_point_t out_p;
  jb_point_t in_p [];
  logic [DAT_BITS-1:0] in_s [];

  out_if.rdy = 0;
  in_if.val = 0;
  #(40*CLK_PERIOD);

  in_s = new[3];
  in_s[0] = 256'd2;
  in_s[1] = 256'd40;
  in_s[2] = 256'd66;

  in_p = new[3];
  in_p[0] = G1_JB;
  in_p[1] = point_mult(256'd2, G1_JB);
  in_p[2] = point_mult(256'd3, G1_JB);

  $display("multiexp");
  print_af_point(to_affine(multiexp(in_s, in_p)));

  $display("multiexp_batch");
  print_af_point(to_affine(multiexp_batch(in_s, in_p)));

  $display("multiexp_window");
  print_af_point(to_affine(multiexp_window(in_s, in_p)));

  begin
    fe_t a, b,c;
    a = 256'd1157920892373161954235709850087907853269984665640564039457584007913129639935;
    b = 256'd1150892373161954235709850087907853269984665640564039457584007913129639935;
    a = fe_to_mont(a);
    b = fe_to_mont(b);
    c = fe_mul_mont(a, b);
    c = fe_from_mont(c);
    //21341727265027142880471099517246738950833759092283089473545508915107362335925
    $display(c);

  end
*/
  #1us $finish();
end
endmodule