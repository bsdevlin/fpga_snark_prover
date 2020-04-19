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

module ec_fpn_dbl_tb ();
import bn128_pkg::*;
import common_pkg::*;

localparam CLK_PERIOD = 100;

localparam CTL_BITS = 8;

localparam DAT_BITS0 = $bits(fe_t);

logic clk, rst;

localparam DAT_IN2 = $bits(fp2_jb_point_t);

fp2_jb_point_t i_p, o_p;

if_axi_stream #(.DAT_BYTS((DAT_IN2+7)/8), .CTL_BITS(CTL_BITS)) i_pnt_if (clk);
if_axi_stream #(.DAT_BYTS((DAT_IN2+7)/8), .CTL_BITS(CTL_BITS)) o_pnt_if (clk);

if_axi_stream #(.DAT_BITS(DAT_BITS0), .CTL_BITS(CTL_BITS))   add_if_i [2:0] (clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS0), .CTL_BITS(CTL_BITS)) add_if_o [2:0](clk);
if_axi_stream #(.DAT_BITS(DAT_BITS0), .CTL_BITS(CTL_BITS))   sub_if_i [2:0](clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS0), .CTL_BITS(CTL_BITS)) sub_if_o [2:0](clk);
if_axi_stream #(.DAT_BITS(DAT_BITS0), .CTL_BITS(CTL_BITS))   mul_fe2_if_i (clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS0), .CTL_BITS(CTL_BITS)) mul_fe2_if_o (clk);
if_axi_stream #(.DAT_BITS(DAT_BITS0), .CTL_BITS(CTL_BITS))   mul_if_i (clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS0), .CTL_BITS(CTL_BITS)) mul_if_o (clk);

always_comb begin
  i_p = i_pnt_if.dat[0 +: DAT_IN2];
  o_pnt_if.dat = o_p;
  o_pnt_if.sop = 1;
  o_pnt_if.eop = 1;
end

initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #(CLK_PERIOD/2) clk = ~clk;
end

ec_fpn_dbl #(
  .FP_TYPE ( fp2_jb_point_t ),
  .FE_TYPE ( fe2_t          ),
  .FE_TYPE_ARITH ( fe_t ),
  .CONST_3  ( CONST_3    ),
  .CONST_4  ( CONST_4    ),
  .CONST_8  ( CONST_8    )
)
ec_fpn_dbl (
  .i_clk ( clk ), 
  .i_rst ( rst ),
  .i_p ( i_p ),
  .i_val ( i_pnt_if.val ),
  .o_rdy ( i_pnt_if.rdy ),
  .o_p ( o_p ),
  .i_rdy ( o_pnt_if.rdy ),
  .o_val ( o_pnt_if.val ),
  .o_err ( o_pnt_if.err ),
  .o_mul_if ( mul_fe2_if_o ),
  .i_mul_if ( mul_fe2_if_i ),
  .o_add_if ( add_if_o[0] ),
  .i_add_if ( add_if_i[0] ),
  .o_sub_if ( sub_if_o[0] ),
  .i_sub_if ( sub_if_i[0] )
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
  .i_mont_mul_if ( mul_if_o  ),
  .o_mont_mul_if ( mul_if_i )
);

ec_fe2_mul_s #(
  .FE_TYPE  ( fe_t     ),
  .CTL_BITS ( CTL_BITS )
  )
ec_fe2_mul_s (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .o_mul_fe2_if ( mul_fe2_if_i ),
  .i_mul_fe2_if ( mul_fe2_if_o ),
  .o_add_fe_if ( add_if_o[1] ),
  .i_add_fe_if ( add_if_i[1] ),
  .o_sub_fe_if ( sub_if_o[1] ),
  .i_sub_fe_if ( sub_if_i[1] ),
  .o_mul_fe_if ( mul_if_o ),
  .i_mul_fe_if ( mul_if_i )
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
  .i_add ( add_if_o[2] ),
  .o_add ( add_if_i[2] )
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
  .i_sub ( sub_if_o[2] ),
  .o_sub ( sub_if_i[2] )
);  

resource_share # (
  .NUM_IN       ( 2            ),
  .DAT_BITS     ( 2*DAT_BITS   ),
  .CTL_BITS     ( CTL_BITS     ),
  .OVR_WRT_BIT  ( CTL_BITS -2  ),
  .PIPELINE_IN  ( 0            ),
  .PIPELINE_OUT ( 0            )
)
resource_share_add (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_axi ( add_if_o[1:0] ),
  .o_res ( add_if_o[2]   ),
  .i_res ( add_if_i[2]   ),
  .o_axi ( add_if_i[1:0] )
);
  
resource_share # (
  .NUM_IN       ( 2            ),
  .DAT_BITS     ( 2*DAT_BITS   ),
  .CTL_BITS     ( CTL_BITS     ),
  .OVR_WRT_BIT  ( CTL_BITS -2  ),
  .PIPELINE_IN  ( 0            ),
  .PIPELINE_OUT ( 0            )
)
resource_share_sub (
  .i_clk ( clk ),
  .i_rst ( rst ),
  .i_axi ( sub_if_o[1:0] ),
  .o_res ( sub_if_o[2]   ),
  .i_res ( sub_if_i[2]   ),
  .o_axi ( sub_if_i[1:0] )
);
  
task test0();
begin
  integer signed get_len;
  logic [common_pkg::MAX_SIM_BYTS*8-1:0] get_dat;
  fp2_jb_point_t out, a;
  fp2_jb_point_t expected;
  
  $display("Running test0...");

  for (int i = 0; i < 100; i++) begin
    a = fp2_point_mult(random_vector((DAT_BITS+7)/8) % P, fp2_jb_to_mont(G2_JB));
    $display("Input point #%d:", i);
    print_fp2_jb_point(a);
    
    expected = dbl_fp2_jb_point(a);
    
    fork
      i_pnt_if.put_stream(a, (DAT_IN2+7)/8, 0);
      o_pnt_if.get_stream(get_dat, get_len, 0);
    join
    
    out = get_dat;
    
    $display("Expected:");
    print_fp2_jb_point(expected);
  
    assert(out == expected) else begin
      $display("Was:");
      print_fp2_jb_point(out);
      $fatal(1, "ERROR: Output did not match");
    end
  end

  $display("test0 PASSED");
end
endtask;

initial begin

  i_pnt_if.reset_source();
  o_pnt_if.rdy = 0;

  #(100*CLK_PERIOD);

  test0();

  #1us $finish();
end
endmodule