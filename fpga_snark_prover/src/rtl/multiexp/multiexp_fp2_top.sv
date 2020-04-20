/*
  Top level for the G2 multiexp block.

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

module multiexp_fp2_top #(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter type FP2_TYPE,
  parameter type FE2_TYPE,  
  parameter      P,
  parameter      NUM_CORES,  // How many parallel cores do we instantiate, should be a power of 2
  parameter      NUM_ARITH,  // How many arithmetic units (mult, add, sub). Divided evenly over number of cores, should be a power of 2
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
  
  input [63:0] i_num_in, // Number of input points to operate on - max is 2^64 - 1

  if_axi_stream.sink i_pnt_scl_if,   // Input stream of points and scalars DAT_BITS wide
  if_axi_stream.source o_pnt_if // Final output DAT_BITS wide
);

localparam NUM_CORE_IN_GRP =  (NUM_CORES+NUM_ARITH-1)/NUM_ARITH;
localparam LOG2_CORE_IN_GRP = (NUM_CORE_IN_GRP == 1 ? 1 : $clog2(NUM_CORE_IN_GRP));

localparam CTL_BITS = 9;
localparam CTL_BITS_INT = CTL_BITS + LOG2_CORE_IN_GRP;
localparam DAT_BITS = $bits(FE_TYPE);
localparam S_BITS = $bits(FE_TYPE);
localparam P_BITS = $bits(FP_TYPE);
localparam P_S_BITS = S_BITS + P_BITS;
localparam LOG2_CORES = (NUM_CORES == 1 ? 1 : $clog2(NUM_CORES));
logic [63:0] num_in;

logic [LOG2_CORES-1:0] core_sel;    // Used when muxing traffic into the cores

logic [NUM_CORES-1:0][LOG2_CORES-1:0] final_map;
logic [NUM_CORES-1:0][LOG2_CORES-1:0] final_map_delta;

logic [$clog2(DAT_BITS)-1:0] key_cnt;
logic [63:0] in_cnt;
logic discard;

if_axi_stream #(.DAT_BITS(S_BITS), .CTL_BITS(CTL_BITS_INT)) pnt_scl_if_add (i_clk);
if_axi_stream #(.DAT_BITS(S_BITS), .CTL_BITS(CTL_BITS_INT)) pnt_scl_in_if (i_clk);
if_axi_stream #(.DAT_BITS(S_BITS), .CTL_BITS(CTL_BITS_INT)) pnt_scl_core_if [NUM_CORES-1:0](i_clk);
if_axi_stream #(.DAT_BITS(S_BITS), .CTL_BITS(CTL_BITS_INT)) core_pnt_if [NUM_CORES-1:0](i_clk);
if_axi_stream #(.DAT_BITS(S_BITS), .CTL_BITS(CTL_BITS_INT)) res_pnt_if (i_clk);  

// Logic for streaming data into cores and adding final output
enum {IDLE, MULTI_EXP, FINAL_ADD} state;

always_comb begin
  res_pnt_if.rdy = (state == FINAL_ADD) && (~pnt_scl_if_add.val || (pnt_scl_if_add.val && pnt_scl_if_add.rdy));
  pnt_scl_if_add.rdy = pnt_scl_in_if.rdy;
  i_pnt_scl_if.rdy = pnt_scl_in_if.rdy && (state == MULTI_EXP);
  if (state == FINAL_ADD) begin
    pnt_scl_in_if.copy_if_comb(pnt_scl_if_add.dat, pnt_scl_if_add.val, pnt_scl_if_add.sop, pnt_scl_if_add.eop, pnt_scl_if_add.err, pnt_scl_if_add.mod, pnt_scl_if_add.ctl);
  end else begin
    pnt_scl_in_if.copy_if_comb(i_pnt_scl_if.dat, i_pnt_scl_if.val && (state == MULTI_EXP), i_pnt_scl_if.sop, i_pnt_scl_if.eop, i_pnt_scl_if.err, i_pnt_scl_if.mod, i_pnt_scl_if.ctl);
    pnt_scl_in_if.ctl[CTL_BITS +: LOG2_CORES] = core_sel; 
  end     
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    state <= IDLE;
    num_in <= 0;
    core_sel <= 0;
    o_pnt_if.reset_source();
    key_cnt <= 0;
    in_cnt <= 0;
    pnt_scl_if_add.reset_source();
    discard <= 0;
    init_final_map();
    init_final_map_delta();
  end else begin
    if (o_pnt_if.rdy) o_pnt_if.val <= 0;
    if (pnt_scl_if_add.rdy) pnt_scl_if_add.val <= 0;
      
    case (state)
      IDLE: begin
        num_in <= i_num_in;
        init_final_map();
        core_sel <= 0;
        key_cnt <= 0;
        in_cnt <= 0;
        pnt_scl_if_add.val <= 0;
        if (i_pnt_scl_if.val && o_pnt_if.val == 0) begin
          state <= MULTI_EXP;
        end
      end
      MULTI_EXP: begin
        if (i_pnt_scl_if.val && i_pnt_scl_if.rdy && i_pnt_scl_if.eop) begin
          core_sel <= (core_sel + 1) % NUM_CORES;
          in_cnt <= (in_cnt == (num_in - 1)) ? 0 : (in_cnt + 1);
          if (in_cnt == num_in-1) begin
            key_cnt <= key_cnt + 1;
            if (key_cnt == DAT_BITS-1) begin
              core_sel <= 0;
              state <= FINAL_ADD;
            end
          end
        end
      end
      // Now we wait for points to be sent back
      FINAL_ADD: begin
        discard <= 0;
        if (res_pnt_if.val && res_pnt_if.rdy) begin
          // First check if this is the final point
          if (final_map[res_pnt_if.ctl[CTL_BITS_INT-1:CTL_BITS]] == 0) begin
            if (res_pnt_if.ctl[CTL_BITS_INT-1:CTL_BITS] == 0) begin
              o_pnt_if.copy_if(res_pnt_if.dat, res_pnt_if.val, res_pnt_if.sop, res_pnt_if.eop, res_pnt_if.err, res_pnt_if.mod, res_pnt_if.ctl);
              if (res_pnt_if.eop) state <= IDLE;
            end else begin
              pnt_scl_if_add.copy_if(res_pnt_if.dat, res_pnt_if.val, res_pnt_if.sop, res_pnt_if.eop, res_pnt_if.err, res_pnt_if.mod, res_pnt_if.ctl);
              pnt_scl_if_add.ctl[CTL_BITS +: LOG2_CORES] <= final_map_delta[res_pnt_if.ctl[CTL_BITS +: LOG2_CORES]];
              pnt_scl_if_add.ctl[0] <= 1; 
            end
          end else begin
            // Discard
            discard <= 1;
            if (res_pnt_if.eop)
              final_map[res_pnt_if.ctl[CTL_BITS_INT-1:CTL_BITS]] <= final_map[res_pnt_if.ctl[CTL_BITS_INT-1:CTL_BITS]] - 1;            
          end
        end
      end
    endcase
  end
end

task init_final_map();
  // each number represents the number of times to discard before using
  final_map = 0;
  for (int i = NUM_CORES/2; i > 0; i=i/2)
    for (int j = 0; j < i; j++)
      final_map[j] = final_map[j] + 1;
      
endtask

task init_final_map_delta();
  for (int i = 0; i < NUM_CORES; i++) begin
    final_map_delta[i] = 1;
    while (final_map_delta[i]*2 <= i)
      final_map_delta[i] = final_map_delta[i]*2;
    final_map_delta[i] = i - final_map_delta[i];
  end
endtask


// Instantiate the cores and arithmetic blocks
tree_packet_arb_1_to_n # (
  .DAT_BITS    ( P_S_BITS     ),
  .CTL_BITS    ( CTL_BITS_INT ),
  .NUM_OUT     ( NUM_CORES    ),
  .N           ( 2            ),
  .OVR_WRT_BIT ( CTL_BITS     )
)
tree_packet_arb_1_to_n_pnt_scl_in (
  .i_clk   ( i_clk ), 
  .i_rst   ( i_rst ),
  .i_axi   ( pnt_scl_in_if ), 
  .o_n_axi ( pnt_scl_core_if )
);

tree_packet_arb_n_to_1 # (
  .DAT_BITS    ( P_BITS       ),
  .CTL_BITS    ( CTL_BITS_INT ),
  .NUM_IN      ( NUM_CORES    ),
  .N           ( 2            ),
  .OVR_WRT_BIT ( CTL_BITS     )
)
tree_packet_arb_n_to_1_pnt_res (
  .i_clk   ( i_clk ), 
  .i_rst   ( i_rst ),
  .i_n_axi ( core_pnt_if ), 
  .o_axi   ( res_pnt_if )
);

genvar gx, gy;
generate
  for (gx = 0; gx < NUM_ARITH; gx++) begin: GROUP_GEN
  
    if_axi_stream #(.DAT_BYTS(DAT_BITS*2/8), .DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS_INT)) mul_if_o [NUM_CORE_IN_GRP:0] (i_clk);
    if_axi_stream #(.DAT_BYTS(DAT_BITS/8), .DAT_BITS(DAT_BITS), .CTL_BITS(CTL_BITS_INT))   mul_if_i [NUM_CORE_IN_GRP:0] (i_clk);
  
    for (gy = 0; gy < NUM_CORE_IN_GRP; gy++) begin: CORE_GEN

      if (gx*NUM_CORE_IN_GRP + gy >= NUM_CORES) begin
        always_comb begin
          mul_if_o[gy].val = 0;
          mul_if_i[gy].rdy = 0;       
        end
        
      end else begin
        multiexp_fp2_core #(
          .FP_TYPE  ( FP_TYPE      ),
          .FE_TYPE  ( FE_TYPE      ),
          .FP2_TYPE ( FP2_TYPE     ),
          .FE2_TYPE ( FE2_TYPE     ),  
          .KEY_BITS ( DAT_BITS     ),
          .CTL_BITS ( CTL_BITS_INT ),
          .CONST_3  ( CONST_3      ),
          .CONST_4  ( CONST_4      ),
          .CONST_8  ( CONST_8      ),
          .P        ( P            )
        )
        multiexp_fp2_core (
          .i_clk ( i_clk ),
          .i_rst ( i_rst ),
          .i_pnt_scl_if ( pnt_scl_core_if[gy] ),
          .i_num_in ( num_in / NUM_CORES      ), // NUM_CORES should be a power of 2
          .o_pnt_if ( core_pnt_if[gy]         ),
          .o_mul_if( mul_if_o[gy]             ),
          .i_mul_if( mul_if_i[gy]             )
        );
      end
    end
    
    montgomery_mult_wrapper #(
      .DAT_BITS    ( DAT_BITS     ),
      .CTL_BITS    ( CTL_BITS_INT ),
      .REDUCE_BITS ( REDUCE_BITS  ),
      .FACTOR      ( FACTOR       ),
      .MASK        ( MASK         ),
      .MULT_TYPE   ( "ACCUM"      ),
      .HIGH_PERF   ( "YES"        ),
      .P           ( P            ),
      .A_DSP_W     ( 27           ),
      .B_DSP_W     ( 17           )
    )
    montgomery_mult_wrapper (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_mont_mul_if ( mul_if_o[NUM_CORE_IN_GRP] ),
      .o_mont_mul_if ( mul_if_i[NUM_CORE_IN_GRP] )
    );

    tree_resource_share # (
      .NUM_IN       ( NUM_CORE_IN_GRP ),
      .DAT_BITS     ( 2*DAT_BITS   ),
      .CTL_BITS     ( CTL_BITS_INT ),
      .OVR_WRT_BIT  ( CTL_BITS     ),
      .N            ( 2            )
    )
    tree_resource_share_mul (
      .i_clk ( i_clk ),
      .i_rst ( i_rst ),
      .i_axi ( mul_if_o[NUM_CORE_IN_GRP-1:0] ),
      .o_res ( mul_if_o[NUM_CORE_IN_GRP]     ),
      .i_res ( mul_if_i[NUM_CORE_IN_GRP]     ),
      .o_axi ( mul_if_i[NUM_CORE_IN_GRP-1:0] )
    );
  end
endgenerate

endmodule