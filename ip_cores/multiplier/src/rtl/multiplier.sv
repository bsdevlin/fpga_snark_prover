/*
  This does a multiplication using programmable width multipliers,
  followed by product accumulation using compressor trees. Next stage then
  does carry propagates.

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

module multiplier #(
  parameter DAT_BITS,
  parameter CTL_BITS,
  parameter A_DSP_W = 26,
  parameter B_DSP_W = 17,
  parameter AGRID_W = 32,
  parameter NUM_ACCUM_PIPE = 2
)(
  input i_clk,
  input i_rst,
  if_axi_stream.sink   i_mul,
  if_axi_stream.source o_mul
);

localparam int NUM_COL = (DAT_BITS+A_DSP_W-1)/A_DSP_W;
localparam int NUM_ROW = (DAT_BITS+B_DSP_W-1)/B_DSP_W;
localparam int NUM_GRID = (2*DAT_BITS+AGRID_W-1)/AGRID_W;
localparam int BIT_LEN = A_DSP_W+B_DSP_W+$clog2(NUM_GRID);
localparam int PIPE = 4+NUM_ACCUM_PIPE;
localparam int GRIDS_PER_PIPE = NUM_GRID/NUM_ACCUM_PIPE;

if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) o_mul_int (i_clk);


logic [A_DSP_W*NUM_COL-1:0] dat_a;
logic [B_DSP_W*NUM_ROW-1:0] dat_b;
(* DONT_TOUCH = "yes" *) logic [A_DSP_W+B_DSP_W-1:0] mul_grid [NUM_COL][NUM_ROW];
logic [(A_DSP_W+B_DSP_W+DAT_BITS*2)-1:0] mul_grid_flat [NUM_COL*NUM_ROW];
logic [NUM_GRID-1:0][BIT_LEN-1:0] accum_out;

logic [NUM_GRID-1:0][BIT_LEN-1:0] accum_grid [NUM_ACCUM_PIPE];
logic [(DAT_BITS*2)-1:0] mul_res [NUM_ACCUM_PIPE];

logic [PIPE-1:0] val, sop, eop;
logic [PIPE-1:0][CTL_BITS-1:0] ctl;

logic adder_rdy_o, adder_val_o, adder_sop_o, adder_eop_o;
logic [CTL_BITS-1:0] adder_ctl_o;

genvar gx, gy;

// Flow control
always_comb begin
  i_mul.rdy = adder_rdy_o;
  o_mul_int.val = val[PIPE-1];
  o_mul_int.sop = sop[PIPE-1];
  o_mul_int.eop = eop[PIPE-1];
  o_mul_int.ctl = ctl[PIPE-1];
  o_mul_int.dat = mul_res[NUM_ACCUM_PIPE-1];
  o_mul_int.err = 0;
  o_mul_int.mod = 0;
end

// Logic for handling multiple pipelines
always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    val <= 0;
    sop <= 0;
    eop <= 0;
    ctl <= 0;
  end else begin
    // Before the pipelined adder
    if (adder_rdy_o) begin
      val[1:0] <= {val[1:0], i_mul.val};
      sop[1:0] <= {sop[1:0], i_mul.sop};
      eop[1:0] <= {eop[1:0], i_mul.eop};
      ctl[1:0] <= {ctl[1:0], i_mul.ctl};
    end
    
    // After the pipelined adder
    if (o_mul_int.rdy) begin
      val[PIPE-1:2] <= {val[PIPE-1:2], adder_val_o};
      sop[PIPE-1:2] <= {sop[PIPE-1:2], adder_sop_o};
      eop[PIPE-1:2] <= {eop[PIPE-1:2], adder_eop_o};
      ctl[PIPE-1:2] <= {ctl[PIPE-1:2], adder_ctl_o};
    end
    
  end
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    dat_a <= 0;
    dat_b <= 0;
    
  end else begin
    if (adder_rdy_o) begin
      dat_a <= 0;
      dat_b <= 0;
      dat_a <= i_mul.dat[0+:DAT_BITS];
      dat_b <= i_mul.dat[DAT_BITS+:DAT_BITS];
    end
  end
end


always_ff @ (posedge i_clk) begin
  for (int i = 0; i < NUM_COL; i++)
    for (int j = 0; j < NUM_ROW; j++) begin
      if (adder_rdy_o)
        mul_grid[i][j] <= dat_a[i*A_DSP_W +: A_DSP_W] * dat_b[j*B_DSP_W +: B_DSP_W];
    end
end

// Convert the multiplication grid into a flat grid
always_comb begin
  for (int i = 0; i < NUM_COL; i++)
    for (int j = 0; j < NUM_ROW; j++) begin
      mul_grid_flat[(i*NUM_ROW)+j] = 0;
      mul_grid_flat[(i*NUM_ROW)+j][(i*A_DSP_W)+(j*B_DSP_W) +: A_DSP_W+B_DSP_W] = mul_grid[i][j];
    end
end

// Accumulate the columns
generate
  for (gx = 0; gx < NUM_GRID; gx++) begin: GEN_ACCUM_GRID

    logic [BIT_LEN-1:0] terms [NUM_COL*NUM_ROW];
    logic adder_rdy, adder_val, adder_sop, adder_eop;
    logic [CTL_BITS-1:0] adder_ctl;

    for (gy = 0; gy < NUM_COL*NUM_ROW; gy++) begin: GEN_ACCUM_VAL

      always_comb begin
        terms[gy] =  mul_grid_flat[gy][gx*AGRID_W +: AGRID_W];
      end
    end
      
    logic [BIT_LEN-1:0] res;
 
    pipe_adder_tree_log_n #(
      .NUM_ELEMENTS    ( NUM_COL*NUM_ROW ),
      .BIT_LEN         ( BIT_LEN         ),
      .CTL_BITS        ( CTL_BITS        ),
      .STAGES_PER_PIPE ( 4               ),
      .N               ( 2               )
    )
    pipe_adder_tree_log_n (
      .i_clk   ( i_clk         ),
      .i_rst   ( i_rst         ),
      .i_terms ( terms         ),
      .i_rdy   ( o_mul_int.rdy ),
      .i_ctl   ( ctl[1]        ),
      .i_sop   ( sop[1]        ),
      .i_eop   ( eop[1]        ),      
      .o_ctl   ( adder_ctl     ),
      .i_val   ( val[1]        ),
      .o_rdy   ( adder_rdy     ),
      .o_val   ( adder_val     ),      
      .o_sop   ( adder_sop     ),  
      .o_eop   ( adder_eop     ),        
      .o_s     ( res   )
    );
    
    if (gx == 0) begin
      always_comb begin
        adder_sop_o = adder_sop;
        adder_eop_o = adder_eop;
        adder_val_o = adder_val;
        adder_ctl_o = adder_ctl;   
        adder_rdy_o = adder_rdy;
      end
    end

    // Add the result
    always_ff @ (posedge i_clk) begin
      if (o_mul_int.rdy)
        accum_out[gx] <= res;
    end

  end
endgenerate

// This stage propagates the carry
generate
  for (gx = 0; gx < NUM_ACCUM_PIPE; gx++) begin: ACCUM_PIPE_GEN
    logic [DAT_BITS*2-1:0] mul_res_comb;
    always_comb begin
      mul_res_comb = gx > 0 ? mul_res[gx-1][(DAT_BITS*2)-1:gx*GRIDS_PER_PIPE*AGRID_W] : 0;
      for (int i = 0; i < GRIDS_PER_PIPE; i++) begin
        mul_res_comb += accum_grid[gx][i+(GRIDS_PER_PIPE*gx)] << i*AGRID_W;
      end
    end
    
    always_ff @ (posedge i_clk) begin
      if (o_mul_int.rdy) begin
        accum_grid[gx] <= gx > 0 ? accum_grid[gx-1] : accum_out;
        mul_res[gx] <= gx > 0 ? {mul_res_comb, mul_res[gx-1][gx*GRIDS_PER_PIPE*AGRID_W-1:0]} : mul_res_comb;
      end
    end

  end
endgenerate

// Single pipeline on output
pipeline_bp_if_single #(
  .DAT_BITS  ( DAT_BITS*2 ),
  .CTL_BITS  ( CTL_BITS   )
)
pipeline_bp_if_single (
  .i_rst ( i_rst     ),
  .i_clk ( i_clk     ),
  .i_if  ( o_mul_int ),
  .o_if  ( o_mul     )
);
endmodule