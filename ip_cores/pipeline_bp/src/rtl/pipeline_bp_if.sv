/*
  Pipelining for an interface. Supports adding random backpressure and valid low cycles.
  
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

module pipeline_bp_if  #(
  parameter DAT_BYTS = 8,
  parameter DAT_BITS = DAT_BYTS*8,
  parameter CTL_BITS = 8,
  parameter NUM_STAGES = 1,
  parameter RANDOM_BP = 0
) (
  input i_rst,
  input i_clk,
  if_axi_stream i_if,
  if_axi_stream o_if
);
  
genvar g0;
generate
  if (NUM_STAGES == 0) begin
    
    always_comb begin
      o_if.dat = i_if.dat;
      o_if.val = i_if.val;
      o_if.sop = i_if.sop;
      o_if.eop = i_if.eop;
      o_if.err = i_if.err;
      o_if.mod = i_if.mod;
      o_if.ctl = i_if.ctl;
      i_if.rdy = o_if.rdy;
    end
    
  end else begin
    
    if_axi_stream #(.DAT_BYTS(DAT_BYTS), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS)) if_stage [NUM_STAGES:0] (i_clk) ;
    
    for (g0 = 0; g0 < NUM_STAGES; g0++) begin : GEN_STAGE
      pipeline_bp_if_single #(
        .DAT_BITS  ( DAT_BITS ),
        .DAT_BYTS  ( DAT_BYTS ),
        .CTL_BITS  ( CTL_BITS ),
        .RANDOM_BP ( RANDOM_BP )
      ) 
      pipeline_bp_if_single (
        .i_rst ( i_rst          ),
        .i_clk ( i_clk          ),
        .i_if  ( if_stage[g0]   ),
        .o_if  ( if_stage[g0+1] )
      );
    end
    
    always_comb begin
      o_if.dat = if_stage[NUM_STAGES].dat;
      o_if.val = if_stage[NUM_STAGES].val;
      o_if.sop = if_stage[NUM_STAGES].sop;
      o_if.eop = if_stage[NUM_STAGES].eop;
      o_if.err = if_stage[NUM_STAGES].err;
      o_if.mod = if_stage[NUM_STAGES].mod;
      o_if.ctl = if_stage[NUM_STAGES].ctl;
      if_stage[NUM_STAGES].rdy = o_if.rdy;
      
      if_stage[0].dat = i_if.dat;
      if_stage[0].val = i_if.val;
      if_stage[0].sop = i_if.sop;
      if_stage[0].eop = i_if.eop;
      if_stage[0].err = i_if.err;
      if_stage[0].mod = i_if.mod;
      if_stage[0].ctl = i_if.ctl;
      i_if.rdy = if_stage[0].rdy;
    end
    
  end
endgenerate
endmodule