/*
  Top level for the multiexp_core. Takes in a stream of scalars
  and points, and does the multiplication and addition
  to get multiexp result (single point output).

  On final pass we send in two points with scalar value set to 1,
  which will just perform point addition.

  We use sliding window method and BRAM

  Each core has it's own multiplier, adder, and subtractor units.

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

module multiexp_core #(
  parameter W_BITS   = 3,      // Number of window bits
  parameter DAT_BITS = 256,    // Number of bits in scalar
  parameter NUM_IN   = 128     // Number of points / scalars in memory to operate on
)(
  input i_clk,
  input i_rst,
  input        i_val,           // Start the multiexp on scalar and points in memory
  output logic o_rdy,
  output logic o_val,           // Output value in memory is valid
  input        i_rdy,
  if_ram.source pnt_ram_if,     // Interface to point memory
  if_ram.source scl_ram_if,     // Interface to scalar memory

  // Interfaces to arithmetic units
  if_axi_stream.source o_mul_if,
  if_axi_stream.sink   i_mul_if,
  if_axi_stream.source o_add_if,
  if_axi_stream.sink   i_add_if,
  if_axi_stream.source o_sub_if,
  if_axi_stream.sink   i_sub_if
);

// First state we use window method to calculate W_BITS
// Total number of adds required is NUM_IN * (DAT_BITS/W_BITS)
// Total number of dbls required is DAT_BITS


endmodule