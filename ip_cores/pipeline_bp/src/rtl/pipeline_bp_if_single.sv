/*
  Pipelining for an interface that supports optional backpressure
  
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

module pipeline_bp_if_single #(
    parameter DAT_BYTS = 8,
    parameter DAT_BITS = DAT_BYTS*8,
    parameter CTL_BITS = 8,
    parameter RANDOM_BP = 0 // Optionally add in random backpressure
    )(
    input i_rst,
    input i_clk,
    if_axi_stream.sink   i_if,
    if_axi_stream.source o_if
  );

  // Need pipeline stage to store temp data
  if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) if_r (i_clk);
  if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) i_if_int (i_clk);

  logic bp;

  always_comb begin
    i_if_int.dat = i_if.dat;
    i_if_int.val = i_if.val && bp;
    i_if_int.mod = i_if.mod;
    i_if_int.ctl = i_if.ctl;
    i_if_int.sop = i_if.sop;
    i_if_int.eop = i_if.eop;
    i_if_int.err = i_if.err;
    i_if.rdy = i_if_int.rdy && bp;
  end

  always_ff @ (posedge i_clk) begin
    bp <= 1;
    // synthesis translate_off
    bp <= RANDOM_BP == 0 ? 1 : (($random % 100) > RANDOM_BP);
    // synthesis translate_on
  end

  always_ff @ (posedge i_clk) begin
    if (i_rst) begin
      o_if.reset_source();
      if_r.reset_source();
      if_r.rdy <= 0;
      i_if_int.rdy <= 0;
    end else begin
      i_if_int.rdy <= (~o_if.val || (o_if.val && o_if.rdy));
    
    
      // Data transfer cases
      if (~o_if.val || (o_if.val && o_if.rdy)) begin
        // First case - second interface is valid
        if (if_r.val) begin
          o_if.dat <= if_r.dat;
          o_if.val <= if_r.val;
          o_if.sop <= if_r.sop;
          o_if.eop <= if_r.eop;
          o_if.err <= if_r.err;
          o_if.mod <= if_r.mod;
          o_if.ctl <= if_r.ctl;
          if_r.val <= 0;
        // Second case - second interface not valid
        end else begin
          o_if.dat <= i_if_int.dat;
          o_if.val <= i_if_int.val;
          o_if.sop <= i_if_int.sop;
          o_if.eop <= i_if_int.eop;
          o_if.err <= i_if_int.err;
          o_if.mod <= i_if_int.mod;
          o_if.ctl <= i_if_int.ctl;
        end
      end
    
      // Check for case where input is valid so we need to store in second interface
      if (i_if_int.rdy && (o_if.val && ~o_if.rdy)) begin
        if_r.dat <= i_if_int.dat;
        if_r.val <= i_if_int.val;
        if_r.sop <= i_if_int.sop;
        if_r.eop <= i_if_int.eop;
        if_r.err <= i_if_int.err;
        if_r.mod <= i_if_int.mod;
        if_r.ctl <= i_if_int.ctl;
        i_if_int.rdy <= 0;
      end
    end
  end
  
endmodule