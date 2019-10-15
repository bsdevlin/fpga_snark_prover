/*
  Top level for the fpga_snark_prover

  Copyright (C) 2019  Benjamin Devlin and Ethereum Foundation

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

module fpga_snark_prover_top
  import fpga_snark_prover_pkg::*;
  import bn128_pkg::*;
#(
)(
  input i_clk, i_rst,
  // Only tx interface is used to send messages to SW on a SEND-INTERRUPT instruction
  if_axi_stream.source tx_if,
  // User access to the instruction, data, and config
  if_axi_lite.sink     axi_lite_if
  // DDR interfaces

);


endmodule