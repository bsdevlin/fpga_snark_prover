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

module tree_packet_arb_n_to_1_tb ();
import common_pkg::*;

localparam CLK_PERIOD = 100;

logic clk, rst;
parameter NUM_IN = 8;
parameter N = 2;

logic [$clog2(NUM_IN)-1:0] index;
logic [NUM_IN-1:0] rdy;

// This is the max size we can expect on the output
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_IN))) out_if(clk);
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_IN))) in_if [NUM_IN-1:0] (clk);
if_axi_stream #(.DAT_BYTS(8), .CTL_BITS($clog2(NUM_IN))) in_if_int (clk);

genvar gi;
generate
  always_comb begin
    in_if_int.rdy = rdy[index];
  end
  for (gi = 0; gi < NUM_IN; gi++) begin : GEN_OUT
    always_comb begin
      in_if[gi].val = in_if_int.val && (index == gi);
      in_if[gi].sop = in_if_int.sop;
      in_if[gi].eop = in_if_int.eop;
      in_if[gi].ctl = in_if_int.ctl;
      in_if[gi].dat = in_if_int.dat;
      in_if[gi].mod = in_if_int.mod;
      in_if[gi].err = in_if_int.err;  
      rdy[gi] = in_if[gi].rdy;
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

tree_packet_arb_n_to_1 # (
  .DAT_BYTS ( 8       ),
  .CTL_BITS ( $clog2(NUM_IN) ),
  .NUM_IN   ( NUM_IN ),
  .PIPELINE ( 1       ),
  .N        ( N       ),
  .OVR_WRT_BIT ( 0 )
)
tree_packet_arb_n_to_1 (
  .i_clk ( clk ), 
  .i_rst ( rst ),
  .i_n_axi ( in_if ), 
  .o_axi ( out_if )
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
    in = random_vector(8*4);
    index = i % NUM_IN;
    fork
      in_if_int.put_stream(in, 8*4, 0);
      begin 
        out_if.get_stream(get_dat, get_len, 0);
        ctl = out_if.ctl;
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
  out_if.rdy = 0;
  in_if_int.reset_source();
  #(40*CLK_PERIOD);

  test_loop();

  #1us $finish();
end
endmodule