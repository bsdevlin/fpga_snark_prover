/*
  Top level for the multiexp_core. Takes in a stream of scalars
  and G2 points, and does the multiplication and addition
  to get multiexp result (single point output).

  Each core has it's own adder, and subtractor units.

  This does not do any pre-calculation.

  Uses 9 bits for control muxing.

  We expect a looping stream of point and scalar pairs, from 0 to NUM_IN-1
  Backpressure is supported in both directions.
 
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

module multiexp_fp2_core #(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter type FP2_TYPE,
  parameter type FE2_TYPE,
  parameter      KEY_BITS,
  parameter      CTL_BITS,
  parameter      P,
  // If using montgomery form need to override these
  parameter FE_TYPE CONST_3 = 3,
  parameter FE_TYPE CONST_4 = 4,
  parameter FE_TYPE CONST_8 = 8
)(
  input i_clk,
  input i_rst,

  if_axi_stream.sink   i_pnt_scl_if,     // Interface to scalar and point - {FE_TYPE} wide. So Fp2 takes 7 clock cycles to transfer a point (scalar is first)
                                         // Ctl[0] == 0 is normal mode. Ctl[0] == 1 is single add mode
  if_axi_stream.source o_pnt_if,         // Interface for final point output - 6 clocks
  
  input [63:0] i_num_in, // Number of input points to operate on - max 2^64 -1

  // Interfaces to arithmetic units
  if_axi_stream.source o_mul_if,
  if_axi_stream.sink   i_mul_if
);

localparam DAT_BITS = $bits(FE_TYPE);

//////// We internally expand the width
if_axi_stream #(.DAT_BITS($bits(FP2_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) i_pnt_scl_int_if (i_clk);
if_axi_stream #(.DAT_BITS($bits(FP2_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) o_pnt_int_if (i_clk);

logic [2:0] out_cnt;

always_comb begin
  i_pnt_scl_if.rdy = ~i_pnt_scl_int_if.val ||  (i_pnt_scl_int_if.val && i_pnt_scl_int_if.rdy);
  o_pnt_int_if.rdy = o_pnt_if.eop && (~o_pnt_if.val || (o_pnt_if.val && o_pnt_if.rdy));
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_pnt_if.reset_source();
    i_pnt_scl_int_if.reset_source();
    out_cnt <= 0;
  end else begin
    if (i_pnt_scl_int_if.rdy) i_pnt_scl_int_if.val <= 0;
    if (o_pnt_if.rdy) o_pnt_if.val <= 0;
    
    if (~i_pnt_scl_int_if.val ||  (i_pnt_scl_int_if.val && i_pnt_scl_int_if.rdy)) begin
      if (i_pnt_scl_if.val) begin
        i_pnt_scl_int_if.val <= i_pnt_scl_if.eop;
        i_pnt_scl_int_if.dat <= {i_pnt_scl_if.dat, i_pnt_scl_int_if.dat[$bits(FP2_TYPE)+DAT_BITS-1:DAT_BITS]};
      end
      i_pnt_scl_int_if.ctl <= i_pnt_scl_if.ctl;
    end
    
    if (~o_pnt_if.val || (o_pnt_if.val && o_pnt_if.rdy)) begin
      o_pnt_if.val <= o_pnt_int_if.val;
      o_pnt_if.dat <= o_pnt_int_if.dat[out_cnt*DAT_BITS +: DAT_BITS];
      o_pnt_if.sop <= out_cnt == 0;
      o_pnt_if.eop <= out_cnt == 5;
      o_pnt_if.ctl <= o_pnt_int_if.ctl;
      if (o_pnt_int_if.val) out_cnt <= out_cnt == 5 ? 0 : out_cnt + 1;
    end
    
  end  
end
//////////////////////////////////////

if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_if_i [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) add_if_o [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   sub_if_i [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) sub_if_o [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   mul_fe2_if_i [2:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) mul_fe2_if_o [2:0] (i_clk);


logic [63:0] num_in;
logic [$clog2(KEY_BITS)-1:0] key_cnt;
logic [63:0] in_cnt;

FP2_TYPE dbl_pnt_o, add_pnt_o, add_dat_i;
logic add_val_o, add_rdy_i, add_rdy_o, add_val_i, add_err_o;
logic dbl_val_o, dbl_rdy_i, dbl_rdy_o, dbl_val_i;
enum {IDLE, DBL, DBL_WAIT, ADD, ADD_WAIT} state;

logic [2:0] i_cnt, o_cnt;

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    i_pnt_scl_int_if.rdy <= 0;
    o_pnt_int_if.reset_source();
    key_cnt <= 0;
    in_cnt <= 0;
    add_rdy_i <= 0;
    dbl_rdy_i <= 0;
    add_dat_i <= 0;
    num_in <= 0;
    {i_cnt, o_cnt} <= 0;
  end else begin

    dbl_rdy_i <= 1;

    o_pnt_int_if.sop <= 1;
    o_pnt_int_if.eop <= 1;

    if (dbl_rdy_o) dbl_val_i <= 0;
    if (add_rdy_o) add_val_i <= 0;
    if (o_pnt_int_if.rdy) o_pnt_int_if.val <= 0;

    case (state)
      IDLE: begin
        num_in <= i_num_in;
        key_cnt <= KEY_BITS-1;
        in_cnt <= 0;
        i_pnt_scl_int_if.rdy <= 0; 
        if (~o_pnt_int_if.val) begin
          o_pnt_int_if.ctl <= i_pnt_scl_int_if.ctl;
          if (i_pnt_scl_int_if.val) begin
            if (i_pnt_scl_int_if.ctl[0] == 0) begin
              o_pnt_int_if.dat <= 0;
              state <= ADD;
            end else begin
            // This is the state used when collapsing multiple core's results together
              add_val_i <= 1;
              i_pnt_scl_int_if.rdy <= 1; 
              add_dat_i <= i_pnt_scl_int_if.dat[0 +: $bits(FP2_TYPE)];
              o_pnt_int_if.val <= 0;
              key_cnt <= 0;
              in_cnt <= i_num_in-1;
              state <= ADD_WAIT;
            end
          end
        end
      end
      DBL: begin
        dbl_val_i <= 1;
        i_pnt_scl_int_if.rdy <= 0;
        state <= DBL_WAIT;
      end
      DBL_WAIT: begin
        if (dbl_val_o) begin
          o_pnt_int_if.dat <= dbl_pnt_o;
          key_cnt <= key_cnt - 1;
          state <= ADD;
        end
      end
      ADD: begin
        i_pnt_scl_int_if.rdy <= 1;
        if (i_pnt_scl_int_if.val && i_pnt_scl_int_if.rdy) begin
          i_pnt_scl_int_if.rdy <= 0;
          if (i_pnt_scl_int_if.dat[key_cnt] == 1) begin
            add_val_i <= 1;
            add_dat_i <= i_pnt_scl_int_if.dat[$bits(FE_TYPE) +: $bits(FP2_TYPE)];
            state <= ADD_WAIT;
          end else if (in_cnt == num_in-1) begin
            in_cnt <= 0;
            if (key_cnt == 0) begin
              o_pnt_int_if.val <= 1;
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
        i_pnt_scl_int_if.rdy <= 0;
        add_rdy_i <= 1;
        if (add_val_o || dbl_val_o) begin
          o_pnt_int_if.dat <= dbl_val_o ? dbl_pnt_o : add_pnt_o;
          if (add_err_o) begin
            // This means the points were the same so we need to double
            dbl_val_i <= 1;
          end else begin          
            if (in_cnt == num_in-1) begin
              in_cnt <= 0;
              if (key_cnt == 0) begin
                o_pnt_int_if.val <= 1;
                add_rdy_i <= 0;
                state <= IDLE;
              end else begin
                state <= DBL;
              end
            end else begin
              i_pnt_scl_int_if.rdy <= 1;
              in_cnt <= in_cnt + 1;
              state <= ADD;
            end
          end
        end
      end
    endcase
  end
end

ec_fpn_add #(
  .FP_TYPE       ( FP2_TYPE ),
  .FE_TYPE       ( FE2_TYPE ),
  .FE_TYPE_ARITH ( FE_TYPE  ),
  .CONST_3       ( CONST_3  )
)
ec_fpn_add (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_p1  ( add_dat_i  ),
  .i_p2  ( o_pnt_int_if.dat ),
  .i_val ( add_val_i ),
  .o_rdy ( add_rdy_o ),
  .o_p   ( add_pnt_o ),
  .i_rdy ( add_rdy_i ),
  .o_val ( add_val_o ),
  .o_err ( add_err_o ),
  .o_mul_if ( mul_fe2_if_o[0] ),
  .i_mul_if ( mul_fe2_if_i[0] ),
  .o_add_if ( add_if_o[0] ),
  .i_add_if ( add_if_i[0] ),
  .o_sub_if ( sub_if_o[0] ),
  .i_sub_if ( sub_if_i[0] )
);

ec_fpn_dbl #(
  .FP_TYPE       ( FP2_TYPE ),
  .FE_TYPE       ( FE2_TYPE ),
  .FE_TYPE_ARITH ( FE_TYPE  ),
  .CONST_3       ( CONST_3  ),
  .CONST_4       ( CONST_4  ),
  .CONST_8       ( CONST_8  )
)
ec_fpn_dbl (
  .i_clk ( i_clk   ),
  .i_rst ( i_rst   ),
  .i_p   ( o_pnt_int_if.dat ),
  .i_val ( dbl_val_i ),
  .o_rdy ( dbl_rdy_o ),
  .o_p   ( dbl_pnt_o ),
  .i_rdy ( dbl_rdy_i ),
  .o_val ( dbl_val_o ),
  .o_err (),
  .o_mul_if ( mul_fe2_if_o[1] ),
  .i_mul_if ( mul_fe2_if_i[1] ),
  .o_add_if ( add_if_o[1] ),
  .i_add_if ( add_if_i[1] ),
  .o_sub_if ( sub_if_o[1] ),
  .i_sub_if ( sub_if_i[1] )
);

ec_fe2_mul_s #(
  .FE_TYPE  ( FE_TYPE  ),
  .CTL_BITS ( CTL_BITS )
)
ec_fe2_mul_s (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .o_mul_fe2_if ( mul_fe2_if_i[2] ),
  .i_mul_fe2_if ( mul_fe2_if_o[2] ),
  .o_add_fe_if ( add_if_o[2] ),
  .i_add_fe_if ( add_if_i[2] ),
  .o_sub_fe_if ( sub_if_o[2] ),
  .i_sub_fe_if ( sub_if_i[2] ),
  .o_mul_fe_if ( o_mul_if ),
  .i_mul_fe_if ( i_mul_if )
);

resource_share # (
  .NUM_IN       ( 3          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_add (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( add_if_o[2:0] ),
  .o_res ( add_if_o[3]   ),
  .i_res ( add_if_i[3]   ),
  .o_axi ( add_if_i[2:0] )
);

resource_share # (
  .NUM_IN       ( 3          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_sub (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( sub_if_o[2:0] ),
  .o_res ( sub_if_o[3]   ),
  .i_res ( sub_if_i[3]   ),
  .o_axi ( sub_if_i[2:0] )
);

// Multiplier is shared between cores
resource_share # (
  .NUM_IN       ( 2          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 8 ),
  .PIPELINE_IN  ( 0 ),
  .PIPELINE_OUT ( 0 )
)
resource_share_mul (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_axi ( mul_fe2_if_o[1:0] ),
  .o_res ( mul_fe2_if_o[2]   ),
  .i_res ( mul_fe2_if_i[2]   ),
  .o_axi ( mul_fe2_if_i[1:0] )
);

// Adder and subtractor are local to core
adder_pipe # (
  .P       ( P        ) ,
  .BITS    ( DAT_BITS ),
  .CTL_BITS( CTL_BITS ),
  .LEVEL   ( 2        )
)
adder_pipe (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_add ( add_if_o[3] ),
  .o_add ( add_if_i[3] )
);

subtractor_pipe # (
  .P       ( P        ),
  .BITS    ( DAT_BITS ),
  .CTL_BITS( CTL_BITS ),
  .LEVEL   ( 2        )
)
subtractor_pipe (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_sub ( sub_if_o[3] ),
  .o_sub ( sub_if_i[3] )
);

endmodule