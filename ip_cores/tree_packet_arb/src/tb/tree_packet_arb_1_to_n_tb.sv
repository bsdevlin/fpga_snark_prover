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
`timescale 1ps/1ps
`define SIMULATION

module tree_packet_arb_1_to_n_tb ();
import common_pkg::*;

localparam CLK_PERIOD = 100;

logic clk, rst;
parameter NUM_OUT = 8;
parameter N = 4;

logic [$clog2(NUM_OUT)-1:0] index;
logic [NUM_OUT-1:0] val, sop, eop;
logic [NUM_OUT-1:0][63:0] dat;
logic [NUM_OUT-1:0][$clog2(NUM_OUT)-1:0] ctl;

// This is the max size we can expect on the output
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_OUT))) in_if(clk);
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_OUT))) out_if [NUM_OUT-1:0] (clk);
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_OUT))) out_if_int (clk);

genvar gi;
generate
  always_comb begin
    out_if_int.val = val[index];
    out_if_int.sop = sop[index];
    out_if_int.eop = eop[index];
    out_if_int.ctl = ctl[index];
    out_if_int.dat = dat[index];
    out_if_int.err = 0;
    out_if_int.mod = 0;
  end
  for (gi = 0; gi < NUM_OUT; gi++) begin : GEN_OUT
    always_comb begin
      val[gi] = out_if[gi].val;
      sop[gi] = out_if[gi].sop;
      eop[gi] = out_if[gi].eop;
      ctl[gi] = out_if[gi].ctl;
      dat[gi] = out_if[gi].dat;
      out_if[gi].rdy = (index == gi) && out_if_int.rdy;
    end
  end
endgenerate

initial begin
  rst = 0;
  repeat(2) #(20*CLK_PERIOD) rst = ~rst;
end

initial begin
  clk = 0;
  forever #CLK_PERIOD clk = ~clk;
end

tree_packet_arb_1_to_n # (
  .DAT_BYTS ( 8       ),
  .CTL_BITS ( $clog2(NUM_OUT) ),
  .NUM_OUT  ( NUM_OUT ),
  .PIPELINE ( 1       ),
  .N        ( N       ),
  .OVR_WRT_BIT ( 0 )
)
tree_packet_arb_1_to_n (
  .i_clk ( clk ), 
  .i_rst ( rst ),
  .i_axi ( in_if ), 
  .o_n_axi ( out_if )
);

task test_loop();
begin
  integer signed get_len;
  logic [common_pkg::MAX_SIM_BYTS*8-1:0] get_dat;
  logic [7:0] ctl;
  logic [8*4*8-1:0] in;
  integer t;
  integer i, max;

  $display("Running test_loop...");
  i = 0;
  max = 1000;

  while (i < max) begin
    in = random_vector(8);
    index = i % NUM_OUT;
    fork
      in_if.put_stream(in, 8*4, index);
      begin 
        out_if_int.get_stream(get_dat, get_len, 0);
        ctl = out_if_int.ctl;
      end
    join


    assert(get_dat == in && ctl == index) else begin
      $display("Expected: 0x%0x ctl 0x%0x", in, index);
      $display("Was:      0x%0x ctl 0x%0x", get_dat, ctl);
      $fatal(1, "ERROR: Output did not match");
    end
    $display("test_loop PASSED loop %0d/%0d - 0x%0x", i, max, get_dat);
    i = i + 1;
  end

  $display("test_loop PASSED");
end
endtask;

initial begin
  index = 0;
  out_if_int.rdy = 0;
  in_if.reset_source();
  #(40*CLK_PERIOD);

  test_loop();

  #1us $finish();
end
endmodule