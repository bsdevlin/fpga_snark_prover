/*
  This is a wrapper around the packet arbitrator that uses a tree structure which is better
  for high fanout signals.
  
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

module tree_packet_arb_n_to_1 # (
  parameter DAT_BYTS,
  parameter DAT_BITS = DAT_BYTS*8,
  parameter CTL_BITS,
  parameter NUM_IN,
  parameter OVR_WRT_BIT = CTL_BITS - $clog2(NUM_IN), // What bits in ctl are overwritten with channel id
  parameter N = 2, //  log n-tree
  parameter MAX = NUM_IN // Don't change
) (
  input i_clk, i_rst,

  if_axi_stream.sink   i_n_axi [NUM_IN-1:0], 
  if_axi_stream.source o_axi
);

localparam MOD_BITS = $clog2(DAT_BYTS);

// Instantiate the level of arbitrators, we build a tree
generate
  genvar g, h;
  // i_n_axi -> o_axi
  localparam NUM_IN_GRP = (NUM_IN+N-1)/N; 
    
  if_axi_stream #(.DAT_BYTS(DAT_BYTS), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) o_axi_int [NUM_IN_GRP-1:0] (i_clk);
    
  for (g = 0; g < NUM_IN_GRP; g++) begin: GEN_TREE
    localparam NUM_IN_INT = (g+1)*N <= NUM_IN ? N : (NUM_IN % N);
    
    if_axi_stream #(.DAT_BYTS(DAT_BYTS), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) i_axi_int [NUM_IN_INT-1:0] (i_clk);
    for (h = 0; h < NUM_IN_INT; h++) begin
      always_comb begin
        i_axi_int[h].copy_if_comb(i_n_axi[g*N + h].dat, i_n_axi[g*N + h].val, i_n_axi[g*N + h].sop, i_n_axi[g*N + h].eop, i_n_axi[g*N + h].err, i_n_axi[g*N + h].mod, i_n_axi[g*N + h].ctl);
        i_n_axi[g*N + h].rdy = i_axi_int[h].rdy;
        if (MAX == NUM_IN)
          i_axi_int[h].ctl[OVR_WRT_BIT +: $clog2(NUM_IN)] = g*N + h;
      end
    end
    
    packet_arb # (
      .DAT_BYTS     ( DAT_BYTS    ),
      .DAT_BITS     ( DAT_BITS    ),
      .CTL_BITS     ( CTL_BITS    ),
      .NUM_IN       ( NUM_IN_INT  ),
      .OVR_WRT_BIT  ( OVR_WRT_BIT ),
      .PIPELINE     ( 1           ),
      .PRIORITY_IN  ( 0           ),
      .OVERRIDE_CTL ( 0           )
    )
    packet_arb (
      .i_clk ( i_clk ), 
      .i_rst ( i_rst ),
      .i_axi ( i_axi_int    ), 
      .o_axi ( o_axi_int[g] )
    );
  end
    
  if (NUM_IN_GRP > 1) begin
    tree_packet_arb_n_to_1 # (
      .DAT_BYTS     ( DAT_BYTS    ),
      .DAT_BITS     ( DAT_BITS    ),
      .CTL_BITS     ( CTL_BITS    ),
      .NUM_IN       ( NUM_IN_GRP  ),
      .OVR_WRT_BIT  ( OVR_WRT_BIT ),
      .N            ( N           ),
      .MAX          ( MAX         )
    ) 
    tree_packet_arb_n_to_1 (
      .i_clk ( i_clk ), 
      .i_rst ( i_rst ),
      .i_n_axi ( o_axi_int ), 
      .o_axi ( o_axi )
    );
  end else begin
    always_comb begin
      o_axi.copy_if_comb(o_axi_int[0].dat, o_axi_int[0].val, o_axi_int[0].sop, o_axi_int[0].eop, o_axi_int[0].err, o_axi_int[0].mod, o_axi_int[0].ctl);
      o_axi_int[0].rdy = o_axi.rdy;
    end
  end
    
endgenerate

endmodule
