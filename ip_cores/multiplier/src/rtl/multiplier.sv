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
  parameter AGRID_W = 32
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
localparam int PIPE = 4;

logic [A_DSP_W*NUM_COL-1:0] dat_a;
logic [B_DSP_W*NUM_ROW-1:0] dat_b;
(* DONT_TOUCH = "yes" *) logic [A_DSP_W+B_DSP_W-1:0] mul_grid [NUM_COL][NUM_ROW];
logic [(A_DSP_W+B_DSP_W+DAT_BITS*2)-1:0] mul_grid_flat [NUM_COL*NUM_ROW];

logic [BIT_LEN-1:0] accum_grid [NUM_GRID];
logic [(DAT_BITS*2)-1:0] mul_res;

logic [PIPE-1:0] val, sop, eop;
logic [PIPE-1:0][CTL_BITS-1:0] ctl;

genvar gx, gy;

// Flow control
always_comb begin
  i_mul.rdy = o_mul.rdy;
  o_mul.val = val[PIPE-1];
  o_mul.sop = sop[PIPE-1];
  o_mul.eop = eop[PIPE-1];
  o_mul.ctl = ctl[PIPE-1];
  o_mul.err = 0;
  o_mul.mod = 0;
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    val <= 0;
    sop <= 0;
    eop <= 0;
    ctl <= 0;
  end else begin
    if (o_mul.rdy) begin
      val <= {val, i_mul.val};
      sop <= {sop, i_mul.sop};
      eop <= {eop, i_mul.eop};
      ctl <= {ctl, i_mul.ctl};
    end
  end
end

// Logic for handling multiple pipelines
always_ff @ (posedge i_clk) begin
  if (o_mul.rdy) begin
    dat_a <= 0;
    dat_b <= 0;
    dat_a <= i_mul.dat[0+:DAT_BITS];
    dat_b <= i_mul.dat[DAT_BITS+:DAT_BITS];
    o_mul.dat <= mul_res;
  end
end


always_ff @ (posedge i_clk) begin
  for (int i = 0; i < NUM_COL; i++)
    for (int j = 0; j < NUM_ROW; j++) begin
      if (o_mul.rdy)
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

    for (gy = 0; gy < NUM_COL*NUM_ROW; gy++) begin: GEN_ACCUM_VAL

      always_comb begin
        terms[gy] =  mul_grid_flat[gy][gx*AGRID_W +: AGRID_W];
      end
    end
      
    logic [BIT_LEN-1:0] res;
 
    adder_tree_log_n #(
      .NUM_ELEMENTS ( NUM_COL*NUM_ROW  ),
      .BIT_LEN      ( BIT_LEN          ),
      .N            ( 3                )
    )
    adder_tree_log_3 (
      .i_terms ( terms ),
      .o_s     ( res   )
    );

    // Add the result
    always_ff @ (posedge i_clk) begin
      if (o_mul.rdy)
        accum_grid[gx] <= res;
    end

  end
endgenerate

// This stage propagates the carry
always_comb begin
  mul_res = 0;
  for (int i = 0; i < NUM_GRID; i++) begin
    mul_res += accum_grid[i] << i*AGRID_W;
  end
end

endmodule