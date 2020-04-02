/*

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

module bn128_multiexp_wrapper
(
  input                i_clk,
  input                i_rst,
  input  logic [63:0]  i_num_in,
  
  input  logic         i_scl_val,
  input  logic [255:0] i_scl_dat,
  output logic         o_scl_rdy,
  
  input  logic         i_pnt_val,
  input  logic [511:0] i_pnt_dat,
  output logic         o_pnt_rdy,
  
  output logic         o_res_val,
  output logic         o_res_sop,
  output logic         o_res_eop,
  output logic [511:0] o_res_dat,
  input  logic         i_res_rdy
);
  
import bn128_pkg::*;

if_axi_stream #(.DAT_BITS($bits(FP_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) pnt_scl_if_add (i_clk);
if_axi_stream #(.DAT_BITS($bits(FP_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) o_pnt_if (i_clk);
logic res_cnt;

always_comb begin
  o_pnt_rdy = i_pnt_scl_if.rdy && i_scl_val;
  o_scl_rdy = i_pnt_scl_if.rdy && i_pnt_val;
  i_pnt_scl_if.val = i_pnt_val && i_scl_val;
  i_pnt_scl_if.dat = {i_pnt_dat, i_scl_dat};
  i_pnt_scl_if.sop = 1;
  i_pnt_scl_if.eop = 1;
  i_pnt_scl_if.ctl = 0;
  i_pnt_scl_if.err = 0;
  o_pnt_if.rdy = res_cnt && (~o_res_val || (o_res_val && i_res_rdy));
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_res_val <= 0;
    o_res_sop <= 0;
    o_res_eop <= 0;
    o_res_dat <= 0;
    res_cnt <= 0;
  end else begin
    if (i_res_rdy && o_res_val) o_res_val <= 0;
    if (~o_res_val || (o_res_val && i_res_rdy)) begin
      case (res_cnt)
        0: begin
          res_cnt <= o_pnt_if.val;
          o_res_val <= o_pnt_if.val;
          o_res_sop <= 1;
          o_res_eop <= 0;
          o_res_dat <= o_pnt_if.dat[0 +: 512];
        end
        1: begin
          res_cnt <= 0;
          o_res_val <= 1;
          o_res_sop <= 0;
          o_res_eop <= 1;
          o_res_dat <= o_pnt_if.dat[512 +: 256];
        end        
      endcase
    end 
  end
end
  
multiexp_top #(
  .FP_TYPE            ( bn128_pkg::jb_point_t       ),
  .FE_TYPE            ( bn128_pkg::fe_t             ),
  .P                  ( bn128_pkg::P                ),
  .NUM_CORES          ( bn128_pkg::NUM_CORES        ),
  .NUM_ARITH          ( bn128_pkg::NUM_ARITH        ),
  .REDUCE_BITS        ( bn128_pkg::MONT_REDUCE_BITS ),
  .FACTOR             ( bn128_pkg::MONT_FACTOR      ),
  .MASK               ( bn128_pkg::MONT_MASK        ),
  .CONST_3            ( bn128_pkg::CONST_3          ),
  .CONST_4            ( bn128_pkg::CONST_4          ),
  .CONST_8            ( bn128_pkg::CONST_8          )
)
multiexp_top (
  .i_clk        ( i_clk        ),
  .i_rst        ( i_rst        ),
  .i_num_in     ( i_num_in     ),
  .i_pnt_scl_if ( i_pnt_scl_if ),
  .o_pnt_if     ( o_pnt_if     )
);
    
    

endmodule