/*
  Wrapper around the montgomery multiplier which includes
  arethmetic units.

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

module montgomery_mult_wrapper #(
  parameter                DAT_BITS,
  parameter                CTL_BITS = 8,
  parameter                A_DSP_W = 26,
  parameter                B_DSP_W = 17,
  parameter                REDUCE_BITS,
  parameter [DAT_BITS-1:0] FACTOR,
  parameter [DAT_BITS-1:0] MASK,
  parameter [DAT_BITS-1:0] P
)(
  input                       i_clk,
  input                       i_rst,
  if_axi_stream.source        o_mont_mul_if,
  if_axi_stream.sink          i_mont_mul_if
);

localparam CTL_BITS_INT = CTL_BITS + 4;

if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) mul_o_if [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) mul_i_if [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*4), .CTL_BITS(CTL_BITS_INT)) add_o_if (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) add_i_if (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) sub_o_if (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT)) sub_i_if (i_clk);

montgomery_mult #(
  .DAT_BITS    ( DAT_BITS     ),
  .CTL_BITS    ( CTL_BITS_INT ),
  .REDUCE_BITS ( REDUCE_BITS  ),
  .FACTOR      ( FACTOR       ),
  .MASK        ( MASK         ),
  .P           ( P            )
)
montgomery_mult (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_mont_mul_if ( i_mont_mul_if ),
  .o_mont_mul_if ( o_mont_mul_if ),
  .o_mul_if_0 ( mul_o_if[0] ),
  .i_mul_if_0 ( mul_i_if[0] ),
  .o_mul_if_1 ( mul_o_if[1] ),
  .i_mul_if_1 ( mul_i_if[1] ),
  .o_mul_if_2 ( mul_o_if[2] ),
  .i_mul_if_2 ( mul_i_if[2] ),
  .o_add_if ( add_o_if ),
  .i_add_if ( add_i_if ),
  .o_sub_if ( sub_o_if ),
  .i_sub_if ( sub_i_if )
);

adder_pipe # (
  .P       ( 0            ) ,
  .BITS    ( DAT_BITS*2   ),
  .CTL_BITS( CTL_BITS_INT ),
  .LEVEL   ( 2            )
)
adder_pipe (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_add ( add_o_if ),
  .o_add ( add_i_if )
);

subtractor_pipe # (
  .P       ( P            ),
  .BITS    ( DAT_BITS     ),
  .CTL_BITS( CTL_BITS_INT ),
  .LEVEL   ( 2            )
)
subtractor_pipe (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_sub ( sub_o_if ),
  .o_sub ( sub_i_if )
);

resource_share # (
  .NUM_IN       ( 3            ),
  .DAT_BITS     ( 2*DAT_BITS   ),
  .CTL_BITS     ( CTL_BITS_INT ),
  .OVR_WRT_BIT  ( CTL_BITS     ),
  .PIPELINE_IN  ( 1            ),
  .PIPELINE_OUT ( 1            )
)
resource_share_mul (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( mul_o_if[2:0] ),
  .o_res ( mul_o_if[3]   ),
  .i_res ( mul_i_if[3]   ),
  .o_axi ( mul_i_if[2:0] )
);

multiplier #(
  .DAT_BITS ( DAT_BITS     ),
  .CTL_BITS ( CTL_BITS_INT ),
  .A_DSP_W  ( A_DSP_W      ),
  .B_DSP_W  ( B_DSP_W      )
)
multiplier (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_mul ( mul_o_if[3] ),
  .o_mul ( mul_i_if[3] )
);

endmodule