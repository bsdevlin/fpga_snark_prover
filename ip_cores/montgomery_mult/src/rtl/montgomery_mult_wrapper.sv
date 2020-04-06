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
  parameter                HIGH_PERF = "YES", // Each multiplier interface gets a dedicated multiplier
  parameter                MULT_TYPE = "ACCUM",  // KARATSUBA or ACCUM
  
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
localparam NUM_ACCUM_PIPE = 2;

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

generate 
  if (HIGH_PERF == "YES") begin: PERF_GEN
  
    if (MULT_TYPE == "KARATSUBA") begin: MULT_GEN
        karatsuba_ofman_mult # (
          .BITS ( DAT_BITS ),
          .CTL_BITS ( CTL_BITS_INT ),
          .LEVEL ( 3 )
        ) 
        multiplier0 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_dat_a ( mul_o_if[0].dat[0 +: DAT_BITS] ),
          .i_dat_b ( mul_o_if[0].dat[DAT_BITS +: DAT_BITS] ),
          .i_val ( mul_o_if[0].val ),
          .i_ctl ( mul_o_if[0].ctl ),
          .i_rdy ( mul_i_if[0].rdy ),
          .o_rdy ( mul_o_if[0].rdy ),
          .o_val ( mul_i_if[0].val ),
          .o_ctl ( mul_i_if[0].ctl ),
          .o_dat ( mul_i_if[0].dat )
        );
    
        karatsuba_ofman_mult # (
          .BITS ( DAT_BITS ),
          .CTL_BITS ( CTL_BITS_INT ),
          .LEVEL ( 3 )
        ) 
        multiplier1 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_dat_a ( mul_o_if[1].dat[0 +: DAT_BITS] ),
          .i_dat_b ( mul_o_if[1].dat[DAT_BITS +: DAT_BITS] ),
          .i_val ( mul_o_if[1].val ),
          .i_ctl ( mul_o_if[1].ctl ),
          .i_rdy ( mul_i_if[1].rdy ),
          .o_rdy ( mul_o_if[1].rdy ),
          .o_val ( mul_i_if[1].val ),
          .o_ctl ( mul_i_if[1].ctl ),
          .o_dat ( mul_i_if[1].dat )
        );
        
        karatsuba_ofman_mult # (
          .BITS ( DAT_BITS ),
          .CTL_BITS ( CTL_BITS_INT ),
          .LEVEL ( 3 )
        ) 
        multiplier2 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_dat_a ( mul_o_if[2].dat[0 +: DAT_BITS] ),
          .i_dat_b ( mul_o_if[2].dat[DAT_BITS +: DAT_BITS] ),
          .i_val ( mul_o_if[2].val ),
          .i_ctl ( mul_o_if[2].ctl ),
          .i_rdy ( mul_i_if[2].rdy ),
          .o_rdy ( mul_o_if[2].rdy ),
          .o_val ( mul_i_if[2].val ),
          .o_ctl ( mul_i_if[2].ctl ),
          .o_dat ( mul_i_if[2].dat )
        );
    end else if (MULT_TYPE == "ACCUM") begin
        multiplier #(
          .DAT_BITS ( DAT_BITS     ),
          .CTL_BITS ( CTL_BITS_INT ),
          .A_DSP_W  ( A_DSP_W      ),
          .B_DSP_W  ( B_DSP_W      ),
          .NUM_ACCUM_PIPE ( NUM_ACCUM_PIPE )
        )
        multiplier0 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_mul ( mul_o_if[0] ),
          .o_mul ( mul_i_if[0] )
        );
        
        multiplier #(
          .DAT_BITS ( DAT_BITS     ),
          .CTL_BITS ( CTL_BITS_INT ),
          .A_DSP_W  ( A_DSP_W      ),
          .B_DSP_W  ( B_DSP_W      ),
          .NUM_ACCUM_PIPE ( NUM_ACCUM_PIPE )
        )
        multiplier1 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_mul ( mul_o_if[1] ),
          .o_mul ( mul_i_if[1] )
        );
        
         multiplier #(
          .DAT_BITS ( DAT_BITS     ),
          .CTL_BITS ( CTL_BITS_INT ),
          .A_DSP_W  ( A_DSP_W      ),
          .B_DSP_W  ( B_DSP_W      ),
          .NUM_ACCUM_PIPE ( NUM_ACCUM_PIPE )
        )
        multiplier2 (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_mul ( mul_o_if[2] ),
          .o_mul ( mul_i_if[2] )
        );   
    end else
      $fatal(1, "Unsupported MULT_TYPE");
  end else begin
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
    
    if (MULT_TYPE == "KARATSUBA") begin:MULT_GEN
       karatsuba_ofman_mult # (
          .BITS ( DAT_BITS ),
          .CTL_BITS ( CTL_BITS_INT ),
          .LEVEL ( 2 )
        ) 
        multiplier (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_dat_a ( mul_o_if[3].dat[0 +: DAT_BITS] ),
          .i_dat_b ( mul_o_if[3].dat[DAT_BITS +: DAT_BITS] ),
          .i_val ( mul_o_if[3].val ),
          .i_ctl ( mul_o_if[3].ctl ),
          .i_rdy ( mul_i_if[3].rdy ),
          .o_rdy ( mul_o_if[3].rdy ),
          .o_val ( mul_i_if[3].val ),
          .o_ctl ( mul_i_if[3].ctl ),
          .o_dat ( mul_i_if[3].dat )
        );
        always_comb begin
          mul_i_if[3].sop = 1;
          mul_i_if[3].eop = 1;
        end
    end else if (MULT_TYPE == "ACCUM") begin
        multiplier #(
          .DAT_BITS ( DAT_BITS     ),
          .CTL_BITS ( CTL_BITS_INT ),
          .A_DSP_W  ( A_DSP_W      ),
          .B_DSP_W  ( B_DSP_W      ),
          .NUM_ACCUM_PIPE ( NUM_ACCUM_PIPE )
        )
        multiplier (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_mul ( mul_o_if[3] ),
          .o_mul ( mul_i_if[3] )
        );
    end else
      $fatal(1, "Unsupported MULT_TYPE");
  end 
endgenerate


endmodule