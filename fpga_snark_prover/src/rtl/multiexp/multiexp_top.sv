/*
  Top level for the multiexp block.

  Takes in a stream of data and divides it over multiple mutlexp_cores,
  where each one calculates in parallel the result of the multiexp.
  Finally we add all the results together to get the multiexp result.

  Input stream is expected to be NUM_IN*DAT_BITS

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

module multiexp_top
#(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter      P,
  parameter      NUM_IN,              // Number of points / scalars in memory to operate on
  parameter      NUM_PARALLEL_CORES,  // How many parallel cores do we instantiate
  parameter      NUM_CORES_PER_ARITH, // How many arithmetic blocks (mult, add, sub) do we share between cores. Should divide evenly.
  // If using montgomery form need to override these
  parameter FE_TYPE CONST_3 = 3,
  parameter FE_TYPE CONST_4 = 4,
  parameter FE_TYPE CONST_8 = 8
)(
  input i_clk,
  input i_rst,

  if_axi_stream.sink i_pnt_scl_if,   // Input stream of points and scalars
  if_axi_stream.source o_pnt_if // Final output
);

localparam CTL_BITS = 8;
localparam CTL_BITS_INT = CTL_BITS + $clog2(NUM_CORES_PER_ARITH);
localparam DAT_BITS = $bits(FE_TYPE);

logic [$clog2(NUM_PARALLEL_CORES)-1:0] core_sel;  // Used when muxing traffic into the cores
if_axi_stream #(.DAT_BITS($bits(FP_TYPE)), .CTL_BITS(CTL_BITS)) pnt_if_o [NUM_PARALLEL_CORES] (i_clk);

// Logic for streaming data into cores and adding final output


// Instantiate the cores and arithmetic blocks
genvar gx, gy;
generate
  for (gx = 0; gx < NUM_PARALLEL_CORES/NUM_CORES_PER_ARITH; gx++) begin: CORE_GEN

    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) mul_o_if [NUM_CORES_PER_ARITH+1] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   mul_i_if [NUM_CORES_PER_ARITH+1] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) add_o_if [NUM_CORES_PER_ARITH+1] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   add_i_if [NUM_CORES_PER_ARITH+1] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) sub_o_if [NUM_CORES_PER_ARITH+1] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   sub_i_if [NUM_CORES_PER_ARITH+1] (i_clk);

    for (gy = 0; gy < NUM_CORES_PER_ARITH; gy++) begin: ARITH_GEN

      localparam THIS_CORE = gx*NUM_CORES_PER_ARITH+gy;

      if_axi_stream #(.DAT_BITS($bits(FP_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) pnt_scl_if_i (i_clk);

      // Control logic
      always_comb begin
        pnt_scl_if_i.val = i_pnt_scl_if.val && (core_sel == THIS_CORE);
        pnt_scl_if_i.dat = i_pnt_scl_if.dat;
        pnt_scl_if_i.sop = i_pnt_scl_if.sop;
        pnt_scl_if_i.eop = i_pnt_scl_if.eop;
        pnt_scl_if_i.ctl = i_pnt_scl_if.ctl;
        pnt_scl_if_i.err = i_pnt_scl_if.err;
        core_rdy[THIS_CORE] = pnt_scl_if_i.rdy;
      end

      multiexp_core #(
        .FP_TYPE  ( FP_TYPE  ),
        .FE_TYPE  ( FE_TYPE  ),
        .KEY_BITS ( DAT_BITS ),
        .CTL_BITS ( CTL_BITS ),
        .NUM_IN   ( NUM_IN / NUM_PARALLEL_CORES ),
        .CONST_3  ( CONST_3  ),
        .CONST_4  ( CONST_4  ),
        .CONST_8  ( CONST_8  )
      )
      multiexp_core (
        .i_clk ( i_clk ),
        .i_rst ( i_rst ),
        .i_pnt_scl_if ( pnt_scl_if_i ),
        .o_pnt_if ( pnt_if_o[THIS_CORE] ),
        .o_mul_if( mul_o_if[gy] ),
        .i_mul_if( mul_i_if[gy] ),
        .o_add_if( add_o_if[gy] ),
        .i_add_if( add_i_if[gy] ),
        .o_sub_if( sub_o_if[gy] ),
        .i_sub_if( sub_i_if[gy] )
      );

    end

    montgomery_mult_wrapper #(
      .DAT_BITS    ( DAT_BITS         ),
      .CTL_BITS    ( CTL_BITS_INT     ),
      .REDUCE_BITS ( MONT_REDUCE_BITS ),
      .FACTOR      ( MONT_FACTOR      ),
      .MASK        ( MONT_MASK        ),
      .P           ( P                ),
      .A_DSP_W     ( 27               ),
      .B_DSP_W     ( 17               )
    )
    montgomery_mult_wrapper (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_mont_mul_if ( mul_o_if[NUM_CORES_PER_ARITH] ),
      .o_mont_mul_if ( mul_i_if[NUM_CORES_PER_ARITH] )
    );

    adder_pipe # (
      .P       ( P            ) ,
      .BITS    ( DAT_BITS     ),
      .CTL_BITS( CTL_BITS_INT ),
      .LEVEL   ( 2            )
    )
    adder_pipe (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_add ( add_o_if[NUM_CORES_PER_ARITH] ),
      .o_add ( add_i_if[NUM_CORES_PER_ARITH] )
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
      .i_sub ( sub_o_if[NUM_CORES_PER_ARITH] ),
      .o_sub ( sub_i_if[NUM_CORES_PER_ARITH] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_sub (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( sub_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( o_sub_if[NUM_CORES_PER_ARITH]     ),
      .i_res ( i_sub_if[NUM_CORES_PER_ARITH]     ),
      .o_axi ( sub_if_i[NUM_CORES_PER_ARITH-1:0] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_add (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( add_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( o_add_if[NUM_CORES_PER_ARITH]     ),
      .i_res ( i_add_if[NUM_CORES_PER_ARITH]     ),
      .o_axi ( add_if_i[NUM_CORES_PER_ARITH-1:0] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_mul (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( mul_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( o_mul_if[NUM_CORES_PER_ARITH]     ),
      .i_res ( i_mul_if[NUM_CORES_PER_ARITH]     ),
      .o_axi ( mul_if_i[NUM_CORES_PER_ARITH-1:0] )
    );
  end

endgenerate

endmodule