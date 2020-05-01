/*******************************************************************************
  Copyright 2019 Benjamin Devlin
  Copyright 2019 Eric Pearson

  Originally based off Eric Pearson's log2 adder but changed to log_n.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*******************************************************************************/


module pipe_adder_tree_log_n #(
  parameter int NUM_ELEMENTS = 4,
  parameter int STAGES_PER_PIPE = 4,
  parameter int BIT_LEN = 16,
  parameter int CTL_BITS = 8,
  parameter int N = 4,
  // Don't change this
  parameter int STAGE = 1
)(
  input i_clk,
  input i_rst,
  input        [BIT_LEN-1:0]  i_terms [NUM_ELEMENTS],
  input        [CTL_BITS-1:0] i_ctl,
  input                       i_rdy,
  input                       i_val,
  input                       i_sop,
  input                       i_eop,
  output logic [CTL_BITS-1:0] o_ctl,
  output logic                o_rdy,
  output logic                o_val,  
  output logic                o_sop,  
  output logic                o_eop,  
  output logic [BIT_LEN-1:0]  o_s
);

generate
  if (NUM_ELEMENTS < N) begin
    always_comb begin
      o_eop = i_eop;
      o_sop = i_sop;        
      o_val = i_val;
      o_ctl = i_ctl;
      o_rdy = i_rdy;
      o_s[BIT_LEN-1:0] = 0;
      for (int i = 0; i < NUM_ELEMENTS; i++)
        o_s[BIT_LEN-1:0] += i_terms[i];
    end
  end else begin
    localparam integer NUM_RESULTS = integer'(NUM_ELEMENTS / N) + (NUM_ELEMENTS % N);

    logic [BIT_LEN-1:0] next_level_terms[NUM_RESULTS];
    logic [BIT_LEN-1:0] next_level_terms_r[NUM_RESULTS];

    pipe_adder_tree_level #(
       .NUM_ELEMENTS ( NUM_ELEMENTS ),
       .BIT_LEN      ( BIT_LEN      ),
       .NUM_RESULTS  ( NUM_RESULTS  ),
       .N            ( N            )
    ) adder_tree_level (
       .i_terms  ( i_terms          ),
       .o_results( next_level_terms )
    );
    
    if_axi_stream #(.DAT_BITS(BIT_LEN*NUM_RESULTS), .CTL_BITS(CTL_BITS)) if_in (i_clk);
    if_axi_stream #(.DAT_BITS(BIT_LEN*NUM_RESULTS), .CTL_BITS(CTL_BITS)) if_out (i_clk);
    // Pipeline here
    if (STAGE % STAGES_PER_PIPE == 0) begin : GEN_PIPELINE
       pipeline_bp_if_single #(
          .DAT_BITS  ( BIT_LEN*NUM_RESULTS ),
          .CTL_BITS  ( CTL_BITS ),
          .RANDOM_BP ( 0        ) // Cannot backpressure here
        )
        pipeline_bp_if_single (
          .i_rst ( i_rst  ),
          .i_clk ( i_clk  ),
          .i_if  ( if_in  ),
          .o_if  ( if_out )
        );
      always_comb begin
        { >> {if_in.dat}} = next_level_terms;
        if_in.val = i_val;
        if_in.err = 0;
        if_in.mod = 0;
        if_in.sop = i_sop;
        if_in.eop = i_eop;
        if_in.ctl = i_ctl;
        { >> {next_level_terms_r}} = if_out.dat;
        o_rdy = if_in.rdy;
      end
    end else begin
      always_comb begin
        next_level_terms_r = next_level_terms;
        if_out.val = i_val;
        if_out.sop = i_sop;
        if_out.eop = i_eop;
        if_out.ctl = i_ctl;
        o_rdy = if_out.rdy;
      end
    end

    pipe_adder_tree_log_n #(
      .NUM_ELEMENTS    ( NUM_RESULTS     ),
      .BIT_LEN         ( BIT_LEN         ),
      .CTL_BITS        ( CTL_BITS        ),
      .STAGES_PER_PIPE ( STAGES_PER_PIPE ),
      .N               ( N               ),
      .STAGE           ( STAGE + 1       )
    ) adder_tree_log_n (
      .i_clk  ( i_clk              ),
      .i_rst  ( i_rst              ),
      .i_terms( next_level_terms_r ),
      .i_sop  ( if_out.sop         ),
      .i_eop  ( if_out.eop         ),
      .i_ctl  ( if_out.ctl         ),
      .o_s    ( o_s                ),
      .i_val  ( if_out.val         ),
      .i_rdy  ( i_rdy              ),
      .o_val  ( o_val              ),
      .o_sop  ( o_sop              ),
      .o_eop  ( o_eop              ),
      .o_rdy  ( if_out.rdy         ),
      .o_ctl  ( o_ctl              )
    );

  end
endgenerate

endmodule

module pipe_adder_tree_level #(
  parameter int NUM_ELEMENTS = 4,
  parameter int BIT_LEN      = 16,
  parameter int N = 4,
  parameter int NUM_RESULTS  = integer'(NUM_ELEMENTS / N) + (NUM_ELEMENTS % N)

)(
  input        [BIT_LEN-1:0] i_terms   [NUM_ELEMENTS],
  output logic [BIT_LEN-1:0] o_results [NUM_RESULTS]
);

always_comb begin
  for (int i=0; i<(NUM_ELEMENTS / N); i++) begin
    o_results[i] = 0;
    for (int j = 0; j < N; j++)
      o_results[i] += i_terms[i*N+j];
   end

   for (int i = 0; i < (NUM_ELEMENTS % N); i++)
     o_results[(NUM_ELEMENTS / N) + i] = i_terms[NUM_ELEMENTS - (NUM_ELEMENTS % N) + i];
end

endmodule
