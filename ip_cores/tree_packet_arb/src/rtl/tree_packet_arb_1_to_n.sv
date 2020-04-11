/*
  This is a wrapper around the packet arbitrator that uses a tree structure which is better
  for high fanout signals. We do a divide operation in the muxing so best to use this with
  powers of 2.
  
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

module tree_packet_arb_1_to_n # (
  parameter DAT_BYTS,
  parameter DAT_BITS = DAT_BYTS*8,
  parameter CTL_BITS,
  parameter NUM_OUT,
  parameter OVR_WRT_BIT = CTL_BITS - $clog2(NUM_OUT), // What bits in ctl are overwritten with channel id
  parameter N = 2, //  log n-tree
  parameter MAX = NUM_OUT // Don't change this
) (
  input i_clk, i_rst,

  if_axi_stream.sink   i_axi, 
  if_axi_stream.source o_n_axi[NUM_OUT-1:0]
);

// This uses pipeline stages
generate
  genvar g, h;
  
  localparam NUM_OUT_GRP = (NUM_OUT+N-1)/N;
  
  
  
  if (NUM_OUT_GRP == 1) begin: FIRST_STAGE_GEN
    logic [NUM_OUT-1:0] rdy_i; 
    always_comb i_axi.rdy = |rdy_i;
    
    for (h = 0; h < NUM_OUT; h++) begin: FINAL_GEN
      logic in_range_i;
      always_comb rdy_i[h] = o_n_axi[h].rdy && in_range_i;
      always_comb in_range_i = i_axi.ctl[OVR_WRT_BIT +: $clog2(MAX)] / (MAX/NUM_OUT) == h;
      always_comb begin
        o_n_axi[h].copy_if_comb(i_axi.dat, i_axi.val && in_range_i, i_axi.sop, i_axi.eop, i_axi.err, i_axi.mod, i_axi.ctl);
      end
    end
        
  end else begin
  
      if_axi_stream #(.DAT_BYTS(DAT_BYTS), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) i_pipe [NUM_OUT_GRP-1:0] (i_clk);
  
      tree_packet_arb_1_to_n # (
        .DAT_BYTS     ( DAT_BYTS    ),
        .DAT_BITS     ( DAT_BITS    ),
        .CTL_BITS     ( CTL_BITS    ),
        .NUM_OUT      ( NUM_OUT_GRP ),
        .OVR_WRT_BIT  ( OVR_WRT_BIT ),
        .N            ( N           ),
        .MAX          ( MAX         )
      ) 
      tree_packet_arb_1_to_n (
        .i_clk ( i_clk ), 
        .i_rst ( i_rst ),
        .i_axi ( i_axi ), 
        .o_n_axi ( i_pipe )
      );  

    for (g = 0; g < NUM_OUT_GRP; g++) begin: GEN_TREE
        localparam NUM_OUT_INT = N;
        if_axi_stream #(.DAT_BYTS(DAT_BYTS), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) o_pipe (i_clk);
        logic [NUM_OUT_INT-1:0] rdy_o;
        
        always_comb o_pipe.rdy = |rdy_o;
        
        pipeline_if  #(
          .DAT_BITS   ( DAT_BITS ),
          .CTL_BITS   ( CTL_BITS ),
          .NUM_STAGES ( 1        )
        )
        pipeline_if_in (
          .i_rst ( i_rst  ),
          .i_if  ( i_pipe[g] ),
          .o_if  ( o_pipe )
        );
        
        for (h = 0; h < NUM_OUT_INT; h++) begin: FINAL_GEN
          logic in_range_o;
          always_comb in_range_o = o_pipe.ctl[OVR_WRT_BIT +: $clog2(MAX)] / (MAX/NUM_OUT) == g*N + h;
          always_comb begin
            rdy_o[h] = o_n_axi[g*N + h].rdy && in_range_o;
            o_n_axi[g*N + h].copy_if_comb(o_pipe.dat, o_pipe.val && in_range_o, o_pipe.sop, o_pipe.eop, o_pipe.err, o_pipe.mod, o_pipe.ctl);
          end
        end

      end
  end
    
endgenerate

endmodule
