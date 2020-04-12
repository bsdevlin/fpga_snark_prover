/*

  TODO: Add a width shrink option.
  
  Copyright (C) 2020  Benjamin Devlin

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

module tree_resource_share # (
  parameter NUM_IN = 4,
  parameter CTL_BITS = 16,
  parameter DAT_BYTS = 8,
  parameter DAT_BITS = DAT_BYTS*8,
  parameter OVR_WRT_BIT = 0,
  parameter N = 2 // Log
) (
  input i_clk, i_rst,

  if_axi_stream.sink   i_axi [NUM_IN-1:0], 
  if_axi_stream.source o_res,
  
  if_axi_stream.sink   i_res, 
  if_axi_stream.source o_axi [NUM_IN-1:0]
);
  
tree_packet_arb_n_to_1 # (
  .DAT_BYTS    ( DAT_BYTS    ),
  .DAT_BITS    ( DAT_BITS    ),
  .CTL_BITS    ( CTL_BITS    ),
  .NUM_IN      ( NUM_IN      ),
  .N           ( N           ),
  .OVR_WRT_BIT ( OVR_WRT_BIT )
)
tree_packet_arb_n_to_1 (
  .i_clk   ( i_clk ), 
  .i_rst   ( i_rst ),
  .i_n_axi ( i_axi ), 
  .o_axi   ( o_res )
);

tree_packet_arb_1_to_n # (
  .DAT_BYTS    ( DAT_BYTS    ),
  .DAT_BITS    ( DAT_BITS    ),
  .CTL_BITS    ( CTL_BITS    ),
  .NUM_OUT     ( NUM_IN      ),
  .N           ( N           ),
  .OVR_WRT_BIT ( OVR_WRT_BIT )
)
tree_packet_arb_1_to_n (
  .i_clk   ( i_clk ), 
  .i_rst   ( i_rst ),
  .i_axi   ( i_res ), 
  .o_n_axi ( o_axi )
);

endmodule