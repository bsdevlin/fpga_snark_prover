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
localparam NUM_WRDS = $bits(FP2_TYPE)/DAT_BITS;

// Fifo on the input in case we need to buffer inputs while our output is being read
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   i_pnt_scl_int_if (i_clk);

axi_stream_fifo #(
  .SIZE     ( 1 << $clog2(NUM_WRDS) ),
  .DAT_BITS ( DAT_BITS              ),
  .CTL_BITS ( CTL_BITS              ),
  .MOD_BITS ( 3                     )
)
input_fifo (
  .i_clk ( i_clk            ), 
  .i_rst ( i_rst            ),
  .i_axi ( i_pnt_scl_if     ),
  .o_axi ( i_pnt_scl_int_if )
);

if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   dbl_pnt_if_o (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_pnt_if_o (i_clk);

if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_pnt0_if_i (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_pnt1_if_i (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   dbl_pnt_if_i (i_clk);


if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   add_if_i [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) add_if_o [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   sub_if_i [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) sub_if_o [3:0] (i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS))   mul_fe2_if_i [2:0] (i_clk);
if_axi_stream #(.DAT_BITS(2*DAT_BITS), .CTL_BITS(CTL_BITS)) mul_fe2_if_o [2:0] (i_clk);


logic [63:0] num_in;
logic [$clog2(KEY_BITS)-1:0] key_cnt;
logic [63:0] in_cnt;
FE_TYPE key_l;

logic [$bits(FP2_TYPE)-1:0] res;
logic [3:0] res_cnt, i_cnt;

enum {IDLE, DBL, DBL_WAIT, ADD, ADD_WAIT, FINISHED} state;

always_comb begin
  i_pnt_scl_int_if.rdy = (state == IDLE || state == ADD) && (~add_pnt0_if_i.val || (add_pnt0_if_i.val && add_pnt0_if_i.rdy)); 
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    o_pnt_if.reset_source();
    key_cnt <= 0;
    in_cnt <= 0;
    i_cnt <= 0;
    res <= 0;
    res_cnt <= 0;
    num_in <= 0;
    key_l <= 0;
    add_pnt_if_o.rdy <= 0;
    dbl_pnt_if_o.rdy <= 0;
    add_pnt0_if_i.reset_source();
    add_pnt1_if_i.reset_source();
    dbl_pnt_if_i.reset_source();
  end else begin
    
    dbl_pnt_if_o.rdy <= 1;
    add_pnt_if_o.rdy <= 1;

    if (o_pnt_if.rdy) o_pnt_if.val <= 0;
    if (dbl_pnt_if_i.rdy) dbl_pnt_if_i.val <= 0;
    if (add_pnt0_if_i.rdy) add_pnt0_if_i.val <= 0;
    if (add_pnt1_if_i.rdy) add_pnt1_if_i.val <= 0;

    case (state)
      IDLE: begin
        num_in <= i_num_in;
        key_cnt <= KEY_BITS-1;
        in_cnt <= 0;
        if (~add_pnt0_if_i.val || (add_pnt0_if_i.val && add_pnt0_if_i.rdy)) begin
          o_pnt_if.ctl <= i_pnt_scl_int_if.ctl;
          if (i_pnt_scl_int_if.val && i_pnt_scl_int_if.ctl[0] == 0) begin
            res <= 0;
            key_l <= i_pnt_scl_int_if.dat;
            i_cnt <= 1;
            state <= ADD;
          end else begin
            // This is the state used when collapsing multiple core's results together
            key_cnt <= 0;
            in_cnt <= i_num_in-1;

            add_pnt0_if_i.dat <= i_pnt_scl_int_if.dat;
            add_pnt0_if_i.val <= i_pnt_scl_int_if.val;
            add_pnt0_if_i.sop <= i_cnt == 0;
            add_pnt0_if_i.eop <= i_cnt == NUM_WRDS-1;
              
            add_pnt1_if_i.dat <= res[DAT_BITS-1:0];
            add_pnt1_if_i.val <= i_pnt_scl_int_if.val;
            add_pnt1_if_i.sop <= i_cnt == 0;
            add_pnt1_if_i.eop <= i_cnt == NUM_WRDS-1;
              
            if (i_pnt_scl_int_if.val) begin
              res <= {dbl_pnt_if_o.dat, res[$bits(FP2_TYPE)-1:DAT_BITS]};
              i_cnt <= i_cnt == NUM_WRDS-1 ? 0 : i_cnt + 1;
              if (i_cnt == NUM_WRDS-1) begin
                state <= ADD_WAIT;
              end
            end
          end
        end
      end
      DBL: begin
        if (~dbl_pnt_if_i.val || (dbl_pnt_if_i.val && dbl_pnt_if_i.rdy)) begin
          
          dbl_pnt_if_i.dat <= res[DAT_BITS-1:0];
          dbl_pnt_if_i.sop <= i_cnt == 0;
          dbl_pnt_if_i.eop <= i_cnt == NUM_WRDS-1;
          dbl_pnt_if_i.val <= 1;
          
          res <= {dbl_pnt_if_o.dat, res[$bits(FP2_TYPE)-1:DAT_BITS]};
          i_cnt <= i_cnt == NUM_WRDS-1 ? 0 : i_cnt + 1;
          
          if (i_cnt == NUM_WRDS-1) state <= DBL_WAIT;
          
        end
      end
      DBL_WAIT: begin
        if (dbl_pnt_if_o.val) begin
          res <= {dbl_pnt_if_o.dat, res[$bits(FP2_TYPE)-1:DAT_BITS]};
          if (dbl_pnt_if_o.eop) begin
            key_cnt <= key_cnt - 1;
            state <= ADD;
          end
        end
      end
      ADD: begin
        if (i_cnt == 0) begin // First clock is the scalar
          key_l <= i_pnt_scl_int_if.dat;
        end
          
        if (~add_pnt0_if_i.val || (add_pnt0_if_i.val && add_pnt0_if_i.rdy)) begin

          add_pnt0_if_i.dat <= i_pnt_scl_int_if.dat;
          add_pnt0_if_i.sop <= i_cnt == 1;
          add_pnt0_if_i.eop <= i_cnt == NUM_WRDS;
          add_pnt0_if_i.val <= i_cnt > 0 && (key_l[KEY_BITS-1] == 1) && i_pnt_scl_int_if.val; // We only add to result if the key bit is 1
          
          add_pnt1_if_i.dat <= res[DAT_BITS-1:0];
          add_pnt1_if_i.sop <= i_cnt == 1;
          add_pnt1_if_i.eop <= i_cnt == NUM_WRDS;
          add_pnt1_if_i.val <= i_cnt > 0 && (key_l[KEY_BITS-1] == 1) && i_pnt_scl_int_if.val; // We only add to result if the key bit is 1
          
          if (i_pnt_scl_int_if.val) begin
            if (i_cnt > 0) 
              res <= {res[DAT_BITS-1:0], res[$bits(FP2_TYPE)-1:DAT_BITS]};
            i_cnt <= i_cnt + 1;
            if (i_cnt == NUM_WRDS) begin //eop
              i_cnt <= 0;
              if (key_l[KEY_BITS-1] == 1) begin
                state <= ADD_WAIT;
              end else if (in_cnt == num_in-1) begin
                in_cnt <= 0;
                if (key_cnt == 0) begin
                  state <= FINISHED;
                end else begin
                  state <= DBL;
                end
              end else begin
                in_cnt <= in_cnt + 1;              
              end
            end
          end
        end
      end
      ADD_WAIT: begin
        if (dbl_pnt_if_o.val || add_pnt_if_o.val) begin
          if (dbl_pnt_if_o.val) res <= {dbl_pnt_if_o.dat, res[$bits(FP2_TYPE)-1:DAT_BITS]};
          if (add_pnt_if_o.val) res <= {add_pnt_if_o.dat, res[$bits(FP2_TYPE)-1:DAT_BITS]};
          
          // Need to do double instead
          if (add_pnt_if_o.err) begin
            dbl_pnt_if_i.dat <= add_pnt_if_o.dat;
            dbl_pnt_if_i.sop <= add_pnt_if_o.sop;
            dbl_pnt_if_i.eop <= add_pnt_if_o.eop;
            dbl_pnt_if_i.val <= add_pnt_if_o.val;
          end
          
          if (((dbl_pnt_if_o.eop && dbl_pnt_if_o.val) || (add_pnt_if_o.eop && add_pnt_if_o.val)) && ~add_pnt_if_o.err) begin
            if (in_cnt == num_in-1) begin
              in_cnt <= 0;
              if (key_cnt == 0) begin
                state <= FINISHED;
              end else begin
                state <= DBL; 
              end
            end else begin
              in_cnt <= in_cnt + 1;
              state <= ADD;
            end
          end
        end
      end
      FINISHED: begin
        if (~o_pnt_if.val || (o_pnt_if.val && o_pnt_if.rdy)) begin
          o_pnt_if.dat <= res[DAT_BITS-1:0];
          res <= {res[DAT_BITS-1:0], res[$bits(FP2_TYPE)-1:DAT_BITS]}; 
          o_pnt_if.val <= 1;
          o_pnt_if.sop <= i_cnt == 0;
          o_pnt_if.eop <= i_cnt == NUM_WRDS-1;
          i_cnt <= i_cnt + 1;
          if (i_cnt == NUM_WRDS-1) begin
            i_cnt <= 0;
            state <= IDLE;
          end
        end  
      end
    endcase
  end
end

ec_fpn_add #(
  .FP_TYPE       ( FP2_TYPE ),
  .FE_TYPE       ( FE2_TYPE ),
  .FE_TYPE_ARITH ( FE_TYPE  )
)
ec_fpn_add (
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_pt1_if ( add_pnt0_if_i ),
  .i_pt2_if ( add_pnt1_if_i ),
  .o_pt_if  ( add_pnt_if_o  ),
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
  .i_clk ( i_clk ),
  .i_rst ( i_rst ),
  .i_pt_if  ( dbl_pnt_if_i ),
  .o_pt_if  ( dbl_pnt_if_o ),
  .o_mul_if ( mul_fe2_if_o[1] ),
  .i_mul_if ( mul_fe2_if_i[1] ),
  .o_add_if ( add_if_o[1] ),
  .i_add_if ( add_if_i[1] ),
  .o_sub_if ( sub_if_o[1] ),
  .i_sub_if ( sub_if_i[1] )
);

// We optionally add this block so that we can operate on fe_t elements
generate
  if ($bits(FE_TYPE) == $bits(FE2_TYPE)/2) begin : GEN_FE2_MUL
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
  end else begin
    always_comb begin
      add_if_i[2].rdy = 1;
      add_if_o[2].reset_source();
      sub_if_i[2].rdy = 1;
      sub_if_o[2].reset_source();
      
      o_mul_if.dat = mul_fe2_if_o[2].dat;
      o_mul_if.val = mul_fe2_if_o[2].val;
      o_mul_if.sop = mul_fe2_if_o[2].sop;
      o_mul_if.eop = mul_fe2_if_o[2].eop;
      o_mul_if.err = 0;
      o_mul_if.mod = 0;
      o_mul_if.ctl = mul_fe2_if_o[2].ctl;
      mul_fe2_if_o[2].rdy = o_mul_if.rdy;
      
      mul_fe2_if_i[2].dat = i_mul_if.dat;
      mul_fe2_if_i[2].val = i_mul_if.val;
      mul_fe2_if_i[2].sop = i_mul_if.sop;
      mul_fe2_if_i[2].eop = i_mul_if.eop;
      mul_fe2_if_i[2].err = 0;
      mul_fe2_if_i[2].mod = 0;
      mul_fe2_if_i[2].ctl = i_mul_if.ctl;
      i_mul_if.rdy = mul_fe2_if_i[2].rdy;
    end

  end
endgenerate


resource_share # (
  .NUM_IN       ( 3          ),
  .DAT_BITS     ( 2*DAT_BITS ),
  .CTL_BITS     ( CTL_BITS   ),
  .OVR_WRT_BIT  ( 6 ),
  .PIPELINE_IN  ( 1 ),
  .PIPELINE_OUT ( 1 )
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
  .PIPELINE_IN  ( 1 ),
  .PIPELINE_OUT ( 1 )
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
  .PIPELINE_IN  ( 1 ),
  .PIPELINE_OUT ( 1 )
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