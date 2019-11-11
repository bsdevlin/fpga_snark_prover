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
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter      W_BITS,      // Number of window bits
  parameter      NUM_IN       // Number of points / scalars in memory to operate on
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

localparam DAT_BITS = $bits(FE_TYPE);

// If we are doing pre computation, we need to create the storage RAM
generate
  if (W_BITS > 0) begin: GEN_PRE_CALC
    if_ram #(.RAM_WIDTH($bits(FP_TYPE)), .RAM_DEPTH(NUM_IN*(1 << W_BITS))) ram_pre_calc0_if(.i_clk(i_clk), .i_rst(i_rst));
    if_ram #(.RAM_WIDTH($bits(FP_TYPE)), .RAM_DEPTH(NUM_IN*(1 << W_BITS))) ram_pre_calc1_if(.i_clk(i_clk), .i_rst(i_rst));
  end
endgenerate

FP_TYPE pre_calc_ram_d;
always_comb ram_pre_calc0_if.d = pre_calc_ram_d;




// First state we use window method to calculate W_BITS
// Total number of adds required is NUM_IN * (DAT_BITS/W_BITS)
// Total number of dbls required is DAT_BITS

enum {IDLE, PRE_CALC, MULTI_EXP} state;

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    o_rdy <= 0;
    o_val <= 0;
    ram_pre_calc1_if.reset_source();
    ram_pre_calc0_if.re <= 1;
    ram_pre_calc0_if.we <= 0;
    ram_pre_calc0_if.a <= 0;
    pre_calc_ram_d <= 0;
  end else begin
    case (state)
      IDLE: begin
        o_rdy <= 1;
        o_val <= 0;
        if (o_rdy && i_val) state <= W_BITS == 0 ? MULTI_EXP : PRE_CALC;
      end
      PRE_CALC: begin

      end
      MULTI_EXP: begin

      end
    endcase
  end
end


ec_point_add
#(
  .FP_TYPE ( FP_TYPE ),
  .FE_TYPE ( FE_TYPE )
)
ec_point_add (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_p1  (),
  .i_p2  (),
  .i_val (),
  .o_rdy (),
  .o_p   (),
  .i_rdy (),
  .o_val (),
  .o_err (),
  .o_mul_if (),
  .i_mul_if (),
  .o_add_if (),
  .i_add_if (),
  .o_sub_if (),
  .i_sub_if ()
);

ec_point_dbl
#(
  .FP_TYPE ( FP_TYPE ),
  .FE_TYPE ( FE_TYPE )
)
ec_point_dbl (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_p   (),
  .i_val (),
  .o_rdy (),
  .o_p   (),
  .i_rdy (),
  .o_val (),
  .o_err (),
  .o_mul_if (),
  .i_mul_if (),
  .o_add_if (),
  .i_add_if (),
  .o_sub_if (),
  .i_sub_if ()
);

uram_reset #(
  .RAM_WIDTH($bits(FP_TYPE)),
  .RAM_DEPTH(NUM_IN*(1 << W_BITS)),
  .PIPELINES(3)
)
data_uram (
  .a ( ram_pre_calc0_if ),
  .b ( ram_pre_calc1_if )
);


endmodule