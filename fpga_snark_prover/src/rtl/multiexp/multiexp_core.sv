/*
  Top level for the multiexp_core. Takes in a stream of scalars
  and points, and does the multiplication and addition
  to get multiexp result (single point output).

  Each core has it's own multiplier, adder, and subtractor units.

  This does not do any pre-calculation.
  
  Uses 8 bits for control muxing.

  We expect a looping stream of point and scalar pairs, from 0 to NUM_IN-1
  Backpressure is supported in both directions

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
  parameter      KEY_BITS,
  parameter      CTL_BITS,
  parameter      NUM_IN,      // Number of points / scalars in memory to operate on
  // If using montgomery form need to override these
  parameter FE_TYPE CONST_3 = 3,
  parameter FE_TYPE CONST_4 = 4,
  parameter FE_TYPE CONST_8 = 8
)(
  input i_clk,
  input i_rst,

  if_axi_stream.sink   i_pnt_scl_if,     // Interface to scalar and point stream pair - {FP_TYPE, FE_TYPE}
  if_axi_stream.source o_pnt_if,         // Interface for final point output

  // Interfaces to arithmetic units
  if_axi_stream.source o_mul_if,
  if_axi_stream.sink   i_mul_if,
  if_axi_stream.source o_add_if,
  if_axi_stream.sink   i_add_if,
  if_axi_stream.source o_sub_if,
  if_axi_stream.sink   i_sub_if
);

localparam DAT_BITS = $bits(FE_TYPE);


if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_if_i [1:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) add_if_o [1:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   sub_if_i [1:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) sub_if_o [1:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   mul_if_i [1:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) mul_if_o [1:0] (i_clk);


logic [$clog2(KEY_BITS)-1:0] key_cnt;
logic [$clog2(NUM_IN)-1:0] in_cnt;


FP_TYPE dbl_pnt_o, add_pnt_o;
logic add_val_o, add_rdy_i, add_rdy_o, add_val_i;
logic dbl_val_o, dbl_rdy_i, dbl_rdy_o, dbl_val_i;
enum {IDLE, DBL, DBL_WAIT, ADD, ADD_WAIT} state;

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    i_pnt_scl_if.rdy <= 0;
    o_pnt_if.reset_source();
    key_cnt <= 0;
    in_cnt <= 0;
    add_rdy_i <= 1;
    dbl_rdy_i <= 1;
  end else begin

    add_rdy_i <= 1;
    dbl_rdy_i <= 1;

    o_pnt_if.sop <= 1;
    o_pnt_if.eop <= 1;

    if (dbl_rdy_o) dbl_val_i <= 0;
    if (add_rdy_o) add_val_i <= 0;
    if (o_pnt_if.rdy) o_pnt_if.val <= 0;

    case (state)
      IDLE: begin
        key_cnt <= KEY_BITS-1;
        in_cnt <= 0;
        i_pnt_scl_if.rdy <= 0;
        if (i_pnt_scl_if.val && ~o_pnt_if.val) begin
          i_pnt_scl_if.rdy <= 1;
          o_pnt_if.dat <= 0;
          state <= ADD;
        end
      end
      DBL: begin
        dbl_val_i <= 1;
        state <= DBL_WAIT;
      end
      DBL_WAIT: begin
        if (dbl_val_o) begin
          o_pnt_if.dat <= dbl_pnt_o;
          i_pnt_scl_if.rdy <= 1;
          key_cnt <= key_cnt - 1;
          state <= ADD;
        end
      end
      ADD: begin
        if (i_pnt_scl_if.val && i_pnt_scl_if.rdy) begin
          if (i_pnt_scl_if.dat[key_cnt] == 1) begin
            i_pnt_scl_if.rdy <= 0;
            add_val_i <= 1;
            state <= ADD_WAIT;
          end else if (in_cnt == NUM_IN-1) begin
            in_cnt <= 0;
            if (key_cnt == 0) begin
              o_pnt_if.val <= 1;
              state <= IDLE;
            end else begin
              state <= DBL;
            end
          end else begin
            in_cnt <= in_cnt + 1;
          end
        end
      end
      ADD_WAIT: begin
        if (add_val_o == 1) begin
          o_pnt_if.dat <= add_pnt_o;
          if (in_cnt == NUM_IN-1) begin
            in_cnt <= 0;
            if (key_cnt == 0) begin
              o_pnt_if.val <= 1;
              state <= IDLE;
            end else begin
              state <= DBL;
            end
          end else begin
            i_pnt_scl_if.rdy <= 1;
            in_cnt <= in_cnt + 1;
            state <= ADD;
          end
        end
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
  .i_p1  ( i_pnt_scl_if.dat[$bits(FE_TYPE) +: $bits(FP_TYPE)] ),
  .i_p2  ( o_pnt_if.dat ),
  .i_val ( add_val_i ),
  .o_rdy ( add_rdy_o ),
  .o_p   ( add_pnt_o ),
  .i_rdy ( add_rdy_i ),
  .o_val ( add_val_o ),
  .o_err (),
  .o_mul_if ( mul_if_o[0] ),
  .i_mul_if ( mul_if_i[0] ),
  .o_add_if ( add_if_o[0] ),
  .i_add_if ( add_if_i[0] ),
  .o_sub_if ( sub_if_o[0] ),
  .i_sub_if ( sub_if_i[0] )
);

ec_point_dbl
#(
  .FP_TYPE ( FP_TYPE ),
  .FE_TYPE ( FE_TYPE ),
  .CONST_3 ( CONST_3 ),
  .CONST_4 ( CONST_4 ),
  .CONST_8 ( CONST_8 )
)
ec_point_dbl (
  .i_clk ( i_clk   ),
  .i_rst ( i_rst   ),
  .i_p   ( o_pnt_if.dat ),
  .i_val ( dbl_val_i ),
  .o_rdy ( dbl_rdy_o ),
  .o_p   ( dbl_pnt_o ),
  .i_rdy ( dbl_rdy_i ),
  .o_val ( dbl_val_o ),
  .o_err (),
  .o_mul_if ( mul_if_o[1] ),
  .i_mul_if ( mul_if_i[1] ),
  .o_add_if ( add_if_o[1] ),
  .i_add_if ( add_if_i[1] ),
  .o_sub_if ( sub_if_o[1] ),
  .i_sub_if ( sub_if_i[1] )
);

resource_share # (
  .NUM_IN       ( 2          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_add (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( add_if_o[1:0] ),
  .o_res ( o_add_if      ),
  .i_res ( i_add_if      ),
  .o_axi ( add_if_i[1:0] )
);

resource_share # (
  .NUM_IN       ( 2          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_sub (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( sub_if_o[1:0] ),
  .o_res ( o_sub_if      ),
  .i_res ( i_sub_if      ),
  .o_axi ( sub_if_i[1:0] )
);

resource_share # (
  .NUM_IN       ( 2          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_mul (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( mul_if_o[1:0] ),
  .o_res ( o_mul_if      ),
  .i_res ( i_mul_if      ),
  .o_axi ( mul_if_i[1:0] )
);

endmodule