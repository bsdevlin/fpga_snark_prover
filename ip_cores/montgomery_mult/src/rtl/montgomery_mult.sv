/*
  Calculates a*b mod n, using Montgomery reduction.
  Does not perform final check of subtracting modulus,
  so you should ensure the reduction values are calculated
  with this in mind (increase REDUCE_BITS by 2).

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

module montgomery_mult #(
  parameter                DAT_BITS,
  parameter                CTL_BITS = 8,
  parameter                REDUCE_BITS,
  parameter [DAT_BITS-1:0] FACTOR,
  parameter [DAT_BITS-1:0] MASK,
  parameter [DAT_BITS-1:0] P
)(
  input                       i_clk,
  input                       i_rst,
  if_axi_stream.source        o_mont_mul_if,
  if_axi_stream.sink          i_mont_mul_if,
  if_axi_stream.source        o_mul_if_0,
  if_axi_stream.sink          i_mul_if_0,
  if_axi_stream.source        o_mul_if_1,
  if_axi_stream.sink          i_mul_if_1,
  if_axi_stream.source        o_mul_if_2,
  if_axi_stream.sink          i_mul_if_2,
  if_axi_stream.source        o_add_if,
  if_axi_stream.sink          i_add_if
);

logic [CTL_BITS-1:0] ctl;
logic [DAT_BITS-1:0] dat;
logic val;
logic rdy;

if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) fifo_in_if(i_clk);
if_axi_stream #(.DAT_BITS(DAT_BITS*2), .CTL_BITS(CTL_BITS)) fifo_out_if(i_clk);
logic fifo_out_full;

// Stage 1 multiplication
always_comb i_mont_mul_if.rdy = (~o_mul_if_0.val || (o_mul_if_0.val && o_mul_if_0.rdy));

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_mul_if_0.reset_source();
  end else begin
    o_mul_if_0.sop <= 1;
    o_mul_if_0.eop <= 1;

    if (o_mul_if_0.rdy) o_mul_if_0.val <= 0;

    if (i_mont_mul_if.rdy) begin
      o_mul_if_0.val <= i_mont_mul_if.val;
      o_mul_if_0.ctl <= i_mont_mul_if.ctl;
      o_mul_if_0.dat <= i_mont_mul_if.dat;
    end
  end
end

// Stage 2 multiplication
always_comb i_mul_if_0.rdy = (~o_mul_if_1.val || (o_mul_if_1.val && o_mul_if_1.rdy)) && fifo_in_if.rdy;


always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_mul_if_1.reset_source();
    fifo_in_if.reset_source();
  end else begin
    if (fifo_in_if.rdy) fifo_in_if.val <= 0;
    if (o_mul_if_1.rdy) o_mul_if_1.val <= 0;

    o_mul_if_1.sop <= 1;
    o_mul_if_1.eop <= 1;

    if (i_mul_if_0.rdy) begin
      o_mul_if_1.val <= i_mul_if_0.val;
      o_mul_if_1.ctl <= i_mul_if_0.ctl;
      o_mul_if_1.dat[0 +: DAT_BITS] <= i_mul_if_0.dat & MASK;
      o_mul_if_1.dat[DAT_BITS +: DAT_BITS] <= FACTOR;
      fifo_in_if.dat <= i_mul_if_0.dat;
      fifo_in_if.ctl <= i_mul_if_0.ctl;
      fifo_in_if.val <= i_mul_if_0.val;
    end
  end
end

// Stage 3 multiplication
always_comb i_mul_if_1.rdy = ~o_mul_if_2.val || (o_mul_if_2.val && o_mul_if_2.rdy);

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_mul_if_2.reset_source();
  end else begin
    if (o_mul_if_2.rdy) o_mul_if_2.val <= 0;

    o_mul_if_2.sop <= 1;
    o_mul_if_2.eop <= 1;

    if (i_mul_if_1.rdy) begin
      o_mul_if_2.val <= i_mul_if_1.val;
      o_mul_if_2.ctl <= i_mul_if_1.ctl;
      o_mul_if_2.dat[0 +: DAT_BITS] <= i_mul_if_1.dat & MASK;
      o_mul_if_2.dat[DAT_BITS +: DAT_BITS] <= P;
    end
  end
end

// Stage 4 addition
always_comb begin
  i_mul_if_2.rdy = (o_add_if.val && o_add_if.rdy) || ~o_add_if.val;
  fifo_out_if.rdy = o_add_if.val && o_add_if.rdy;
end

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_add_if.reset_source();
  end else begin
    if (o_add_if.rdy) o_add_if.val <= 0;

    o_add_if.sop <= 1;
    o_add_if.eop <= 1;

    if (i_mul_if_2.rdy) begin
      o_add_if.val <= i_mul_if_2.val;
      o_add_if.ctl <= i_mul_if_2.ctl;
      o_add_if.dat[0 +: 2*DAT_BITS] <= i_mul_if_2.dat;
      o_add_if.dat[2*DAT_BITS +: 2*DAT_BITS] <= fifo_out_if.dat;
    end
  end
end

// Stage 5 shift
always_comb i_add_if.rdy = (o_mont_mul_if.rdy && o_mont_mul_if.val) || ~o_mont_mul_if.val;

always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_mont_mul_if.reset_source();
  end else begin

    if (o_mont_mul_if.rdy) o_mont_mul_if.val <= 0;

    o_mont_mul_if.sop <= 1;
    o_mont_mul_if.eop <= 1;

    if (i_add_if.rdy) begin
      o_mont_mul_if.val <= i_add_if.val;
      o_mont_mul_if.ctl <= i_add_if.ctl;
      o_mont_mul_if.dat <= i_add_if.dat >> REDUCE_BITS;
    end
  end
end

// Fifo to store inputs (as we need to do final add and control)
axi_stream_fifo #(
  .SIZE     ( 16         ),
  .DAT_BITS ( DAT_BITS*2 ),
  .CTL_BITS ( CTL_BITS   )
)
axi_stream_fifo (
  .i_clk ( i_clk         ),
  .i_rst ( i_rst         ),
  .i_axi ( fifo_in_if    ),
  .o_axi ( fifo_out_if   ),
  .o_full( fifo_out_full ),
  .o_emp()
);


endmodule