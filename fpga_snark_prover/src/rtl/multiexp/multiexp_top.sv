/*
  Top level for the multiexp block.

  Takes in a stream of data and divides it over multiple mutlexp_cores,
  where each one calculates in parallel the result of the multiexp.
  Finally we add all the results together to get the multiexp result.

  Input stream is expected to be NUM_IN*DAT_BITS

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

module multiexp_top
#(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter      P,
  parameter      NUM_IN,              // Number of points / scalars in memory to operate on
  parameter      NUM_PARALLEL_CORES,  // How many parallel cores do we instantiate, should be a power of 2
  parameter      NUM_CORES_PER_ARITH, // How many arithmetic blocks (mult, add, sub) do we share between cores. Should divide evenly.
  // If using montgomery form need to override these
  parameter                REDUCE_BITS,
  parameter [DAT_BITS-1:0] FACTOR,
  parameter [DAT_BITS-1:0] MASK,
  parameter FE_TYPE CONST_3 = 3,
  parameter FE_TYPE CONST_4 = 4,
  parameter FE_TYPE CONST_8 = 8
)(
  input i_clk,
  input i_rst,

  if_axi_stream.sink i_pnt_scl_if,   // Input stream of points and scalars
  if_axi_stream.source o_pnt_if // Final output
);

localparam CTL_BITS = 8;
localparam CTL_BITS_INT = CTL_BITS + $clog2(NUM_CORES_PER_ARITH);
localparam DAT_BITS = $bits(FE_TYPE);

logic [$clog2(NUM_PARALLEL_CORES)-1:0] core_sel;    // Used when muxing traffic into the cores
logic [$clog2(NUM_PARALLEL_CORES):0] final_stage; // When doing the final add
logic [$clog2(DAT_BITS)-1:0] key_cnt;
logic [$clog2(NUM_IN)-1:0] in_cnt;
logic [NUM_PARALLEL_CORES-1:0] core_rdy;

if_axi_stream #(.DAT_BITS($bits(FP_TYPE)), .CTL_BITS(CTL_BITS)) pnt_if_o (i_clk);
if_axi_stream #(.DAT_BITS($bits(FP_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) pnt_scl_if_add (i_clk);
logic [NUM_PARALLEL_CORES-1:0] pnt_val_o;
logic [NUM_PARALLEL_CORES-1:0] [$bits(FP_TYPE)-1:0] pnt_dat_o;

// Logic for streaming data into cores and adding final output
enum {IDLE, MULTI_EXP, FINAL_ADD} state;

always_comb begin
  i_pnt_scl_if.rdy = core_rdy[core_sel] && (state == MULTI_EXP) && o_pnt_if.val == 0;
  pnt_scl_if_add.rdy = core_rdy[core_sel] && (state == FINAL_ADD);
  pnt_if_o.dat = pnt_dat_o[core_sel];
  pnt_if_o.val = pnt_val_o[core_sel];
  pnt_if_o.mod = 0;
  pnt_if_o.sop = 1;
  pnt_if_o.eop = 1;
  pnt_if_o.ctl = 0;
  pnt_if_o.err = 0;
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    core_sel <= 0;
    pnt_if_o.rdy <= 0;
    o_pnt_if.reset_source();
    key_cnt <= 0;
    in_cnt <= 0;
    final_stage <= 0;
    pnt_scl_if_add.reset_source();
  end else begin
  
    if (core_rdy[core_sel]) pnt_scl_if_add.val <= 0;
    if (o_pnt_if.rdy) o_pnt_if.val <= 0;
      
    case (state)
      IDLE: begin
        core_sel <= 0;
        key_cnt <= 0;
        in_cnt <= 0;
        pnt_if_o.rdy <= 0;
        pnt_scl_if_add.val <= 0;
        final_stage <= 1;
        if (i_pnt_scl_if.val && o_pnt_if.val == 0) begin
          state <= MULTI_EXP;
        end
      end
      MULTI_EXP: begin
        if (i_pnt_scl_if.val && i_pnt_scl_if.rdy) begin
          core_sel <= (core_sel + 1) % NUM_PARALLEL_CORES;
          in_cnt <= (in_cnt + 1) % NUM_IN;
          if (in_cnt == NUM_IN-1) begin
            key_cnt <= key_cnt + 1;
            if (key_cnt == DAT_BITS-1) begin
              core_sel <= 0;
              state <= FINAL_ADD;
            end
          end
        end
      end
      FINAL_ADD: begin
        if (core_rdy[core_sel] && pnt_scl_if_add.val) begin
          core_sel <= core_sel + 2*final_stage;
          if (core_sel + 2*final_stage == NUM_PARALLEL_CORES) begin
            core_sel <= 0;
            final_stage <= 2*final_stage;
          end
        end
        if (pnt_val_o[core_sel+final_stage] && pnt_val_o[core_sel]) begin
          pnt_scl_if_add.dat <= {pnt_dat_o[core_sel+final_stage], {DAT_BITS{1'd0}}};
          pnt_scl_if_add.val <= 1;
        end
        if (pnt_val_o[0] && (final_stage == NUM_PARALLEL_CORES)) begin
          o_pnt_if.val <= 1;
          o_pnt_if.dat <= pnt_dat_o[0];
          o_pnt_if.sop <= 1;
          o_pnt_if.eop <= 1;
          state <= IDLE;
        end
      end
    endcase
  end
end

// Instantiate the cores and arithmetic blocks
genvar gx, gy;
generate
  for (gx = 0; gx < NUM_PARALLEL_CORES/NUM_CORES_PER_ARITH; gx++) begin: CORE_GEN

    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) mul_if_o [NUM_CORES_PER_ARITH:0] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   mul_if_i [NUM_CORES_PER_ARITH:0] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) add_if_o [NUM_CORES_PER_ARITH:0] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   add_if_i [NUM_CORES_PER_ARITH:0] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) sub_if_o [NUM_CORES_PER_ARITH:0] (i_clk);
    if_axi_stream #(.DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   sub_if_i [NUM_CORES_PER_ARITH:0] (i_clk);

    for (gy = 0; gy < NUM_CORES_PER_ARITH; gy++) begin: ARITH_GEN

      localparam THIS_CORE = gx*NUM_CORES_PER_ARITH+gy;

      if_axi_stream #(.DAT_BITS($bits(FP_TYPE)+DAT_BITS), .CTL_BITS(CTL_BITS)) pnt_scl_if_i (i_clk);
      if_axi_stream #(.DAT_BITS($bits(FP_TYPE)), .CTL_BITS(CTL_BITS)) pnt_if_o (i_clk);

      // Control logic
      always_comb begin
        core_rdy[THIS_CORE] = pnt_scl_if_i.rdy;
        pnt_scl_if_i.dat = 0;
        pnt_scl_if_i.sop = 1;
        pnt_scl_if_i.eop = 1;
        pnt_scl_if_i.ctl = 0;
        pnt_scl_if_i.mod = 0;
        pnt_scl_if_i.err = 0;
        pnt_scl_if_i.val = 0;
        
        if (state == MULTI_EXP) begin
          pnt_scl_if_i.val = i_pnt_scl_if.val && (core_sel == THIS_CORE);
          pnt_scl_if_i.dat = i_pnt_scl_if.dat;
        end else if (state == FINAL_ADD) begin
          pnt_scl_if_i.val = pnt_scl_if_add.val && (core_sel == THIS_CORE);
          pnt_scl_if_i.dat = pnt_scl_if_add.dat;
          pnt_scl_if_i.ctl[0] = 1;
        end
        
        pnt_if_o.rdy = (state == IDLE);
        pnt_val_o[THIS_CORE] = pnt_if_o.val;
        pnt_dat_o[THIS_CORE] = pnt_if_o.dat;
      end

      multiexp_core #(
        .FP_TYPE  ( FP_TYPE  ),
        .FE_TYPE  ( FE_TYPE  ),
        .KEY_BITS ( DAT_BITS ),
        .CTL_BITS ( CTL_BITS ),
        .NUM_IN   ( NUM_IN / NUM_PARALLEL_CORES ),
        .CONST_3  ( CONST_3  ),
        .CONST_4  ( CONST_4  ),
        .CONST_8  ( CONST_8  )
      )
      multiexp_core (
        .i_clk ( i_clk ),
        .i_rst ( i_rst ),
        .i_pnt_scl_if ( pnt_scl_if_i ),
        .o_pnt_if ( pnt_if_o    ),
        .o_mul_if( mul_if_o[gy] ),
        .i_mul_if( mul_if_i[gy] ),
        .o_add_if( add_if_o[gy] ),
        .i_add_if( add_if_i[gy] ),
        .o_sub_if( sub_if_o[gy] ),
        .i_sub_if( sub_if_i[gy] )
      );
    end

    montgomery_mult_wrapper #(
      .DAT_BITS    ( DAT_BITS     ),
      .CTL_BITS    ( CTL_BITS_INT ),
      .REDUCE_BITS ( REDUCE_BITS  ),
      .FACTOR      ( FACTOR       ),
      .MASK        ( MASK         ),
      .P           ( P            ),
      .A_DSP_W     ( 27           ),
      .B_DSP_W     ( 17           )
    )
    montgomery_mult_wrapper (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_mont_mul_if ( mul_if_o[NUM_CORES_PER_ARITH] ),
      .o_mont_mul_if ( mul_if_i[NUM_CORES_PER_ARITH] )
    );

    adder_pipe # (
      .P       ( P            ) ,
      .BITS    ( DAT_BITS     ),
      .CTL_BITS( CTL_BITS_INT ),
      .LEVEL   ( 2            )
    )
    adder_pipe (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_add ( add_if_o[NUM_CORES_PER_ARITH] ),
      .o_add ( add_if_i[NUM_CORES_PER_ARITH] )
    );

    subtractor_pipe # (
      .P       ( P            ),
      .BITS    ( DAT_BITS     ),
      .CTL_BITS( CTL_BITS_INT ),
      .LEVEL   ( 2            )
    )
    subtractor_pipe (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_sub ( sub_if_o[NUM_CORES_PER_ARITH] ),
      .o_sub ( sub_if_i[NUM_CORES_PER_ARITH] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_sub (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( sub_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( sub_if_o[NUM_CORES_PER_ARITH]     ),
      .i_res ( sub_if_i[NUM_CORES_PER_ARITH]     ),
      .o_axi ( sub_if_i[NUM_CORES_PER_ARITH-1:0] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_add (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( add_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( add_if_o[NUM_CORES_PER_ARITH]     ),
      .i_res ( add_if_i[NUM_CORES_PER_ARITH]     ),
      .o_axi ( add_if_i[NUM_CORES_PER_ARITH-1:0] )
    );

    resource_share # (
      .NUM_IN       ( NUM_CORES_PER_ARITH ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .PIPELINE_IN  ( 1 ),
      .PIPELINE_OUT ( 1 )
    )
    resource_share_mul (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( mul_if_o[NUM_CORES_PER_ARITH-1:0] ),
      .o_res ( mul_if_o[NUM_CORES_PER_ARITH]     ),
      .i_res ( mul_if_i[NUM_CORES_PER_ARITH]     ),
      .o_axi ( mul_if_i[NUM_CORES_PER_ARITH-1:0] )
    );
  end

endgenerate

endmodule