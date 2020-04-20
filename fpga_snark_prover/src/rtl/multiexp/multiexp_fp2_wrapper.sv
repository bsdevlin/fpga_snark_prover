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

module bn128_fp2_multiexp_wrapper
(
  input                i_clk,
  input                i_rst,
  input  logic [63:0]  i_num_in,
  
  if_axi_stream.sink   i_scl_if,  // 256 bits
  if_axi_stream.sink   i_pnt_if,  // 512 bits
  if_axi_stream.source o_res_if   // 512 bits
);

import bn128_pkg::*;

if_axi_stream #(.DAT_BITS($bits(bn128_pkg::fe_t)), .CTL_BITS(1)) i_pnt_scl_if (i_clk);
if_axi_stream #(.DAT_BITS($bits(bn128_pkg::fe_t)), .CTL_BITS(1)) o_pnt_if (i_clk);
logic [2:0] o_res_cnt;
logic [2:0] i_cnt;


always_comb begin
  i_pnt_if.rdy = (i_cnt == 2 || i_cnt == 4) && (~i_pnt_scl_if.val || (i_pnt_scl_if.val && i_pnt_scl_if.rdy));
  i_scl_if.rdy = (i_cnt == 0) && (~i_pnt_scl_if.val || (i_pnt_scl_if.val && i_pnt_scl_if.rdy));
  o_pnt_if.rdy = (~o_res_if.val || (o_res_if.val && o_res_if.rdy));
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    i_pnt_scl_if.reset_source();
    i_cnt <= 0;
  end else begin
    
    if (i_pnt_scl_if.rdy) i_pnt_scl_if.val <= 0;
    
    if (~i_pnt_scl_if.val || (i_pnt_scl_if.val && i_pnt_scl_if.rdy)) begin
      i_pnt_scl_if.sop <= 0;
      i_pnt_scl_if.eop <= 0;
      case(i_cnt)
        0: begin
          i_pnt_scl_if.sop <= 1;
          i_pnt_scl_if.dat <= i_scl_if.dat;
          if (i_scl_if.val) begin
            i_cnt <= i_cnt + 1;
            i_pnt_scl_if.val <= 1;
          end
        end
        1: begin
          i_pnt_scl_if.dat <= i_pnt_if.dat[0 +: 256];
          if (i_pnt_if.val) begin
            i_cnt <= i_cnt + 1;
            i_pnt_scl_if.val <= 1;
          end
        end
        2: begin
          i_pnt_scl_if.dat <= i_pnt_if.dat[256 +: 256];
          if (i_pnt_if.val) begin
            i_cnt <= i_cnt + 1;
            i_pnt_scl_if.val <= 1;
          end
        end
        3: begin
          i_pnt_scl_if.dat <= i_pnt_if.dat[0 +: 256];
          if (i_pnt_if.val) begin
            i_cnt <= i_cnt + 1;
            i_pnt_scl_if.val <= 1;
          end
        end
        4: begin
          i_pnt_scl_if.dat <= i_pnt_if.dat[256 +: 256];
          if (i_pnt_if.val) begin
            i_cnt <= i_cnt + 1;
            i_pnt_scl_if.val <= 1;
          end
        end        
        5: begin
          i_pnt_scl_if.dat <= bn128_pkg::CONST_1;
          i_cnt <= i_cnt + 1;
          i_pnt_scl_if.val <= 1;
        end
        6: begin
          i_pnt_scl_if.dat <= 0;
          i_cnt <= 0;
          i_pnt_scl_if.eop <= 1;
          i_pnt_scl_if.val <= 1;
        end          
      endcase
      
    end 
  end
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_res_if.reset_source();
    o_res_cnt <= 0;
  end else begin
    
    if (o_res_if.rdy) o_res_if.val <= 0;
    
    if (~o_res_if.val || (o_res_if.val && o_res_if.rdy)) begin

      if (o_pnt_if.val) begin
        o_res_cnt <= o_res_cnt == 5 ? 0 : o_res_cnt + 1;
        o_res_if.val <= (o_res_cnt == 1) || (o_res_cnt == 3) || (o_res_cnt == 5);
        o_res_if.sop <= o_res_cnt == 0;
        o_res_if.eop <= o_res_cnt == 5;
        o_res_if.dat[(o_res_cnt % 2)*256 +: 256] <= o_pnt_if.dat;
      end
      
    end 
  end
end
  
multiexp_fp2_top #(
  .FP_TYPE            ( bn128_pkg::jb_point_t            ),
  .FE_TYPE            ( bn128_pkg::fe_t                  ),
  .FP2_TYPE           ( bn128_pkg::fp2_jb_point_t        ),
  .FE2_TYPE           ( bn128_pkg::fe2_t                 ),  
  .P                  ( bn128_pkg::P                     ),
  .NUM_CORES          ( bn128_pkg::NUM_G2_MULTIEXP_CORES ),
  .NUM_ARITH          ( bn128_pkg::NUM_G2_MULTIEXP_ARITH ),
  .REDUCE_BITS        ( bn128_pkg::MONT_REDUCE_BITS      ),
  .FACTOR             ( bn128_pkg::MONT_FACTOR           ),
  .MASK               ( bn128_pkg::MONT_MASK             ),
  .CONST_3            ( bn128_pkg::CONST_3               ),
  .CONST_4            ( bn128_pkg::CONST_4               ),
  .CONST_8            ( bn128_pkg::CONST_8               )
)
multiexp_fp2_top (
  .i_clk         ( i_clk         ),
  .i_rst         ( i_rst         ),
  .i_num_in      ( i_num_in      ),
  .i_pnt_scl_if  ( i_pnt_scl_if  ),
  .o_pnt_if      ( o_pnt_if      )
);
    
    

endmodule