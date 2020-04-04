// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
module multiexp_kernel_example #(
  parameter integer C_POINT_ADDR_WIDTH  = 64 ,
  parameter integer C_POINT_DATA_WIDTH  = 512,
  parameter integer C_SCALAR_ADDR_WIDTH = 64 ,
  parameter integer C_SCALAR_DATA_WIDTH = 256,
  parameter integer C_RESULT_ADDR_WIDTH = 64 ,
  parameter integer C_RESULT_DATA_WIDTH = 512
)
(
  // System Signals
  input  wire                             ap_clk        ,
  input  wire                             ap_rst_n      ,
  // AXI4 master interface point
  output wire                             point_awvalid ,
  input  wire                             point_awready ,
  output wire [C_POINT_ADDR_WIDTH-1:0]    point_awaddr  ,
  output wire [8-1:0]                     point_awlen   ,
  output wire                             point_wvalid  ,
  input  wire                             point_wready  ,
  output wire [C_POINT_DATA_WIDTH-1:0]    point_wdata   ,
  output wire [C_POINT_DATA_WIDTH/8-1:0]  point_wstrb   ,
  output wire                             point_wlast   ,
  input  wire                             point_bvalid  ,
  output wire                             point_bready  ,
  output wire                             point_arvalid ,
  input  wire                             point_arready ,
  output wire [C_POINT_ADDR_WIDTH-1:0]    point_araddr  ,
  output wire [8-1:0]                     point_arlen   ,
  input  wire                             point_rvalid  ,
  output wire                             point_rready  ,
  input  wire [C_POINT_DATA_WIDTH-1:0]    point_rdata   ,
  input  wire                             point_rlast   ,
  // AXI4 master interface scalar
  output wire                             scalar_awvalid,
  input  wire                             scalar_awready,
  output wire [C_SCALAR_ADDR_WIDTH-1:0]   scalar_awaddr ,
  output wire [8-1:0]                     scalar_awlen  ,
  output wire                             scalar_wvalid ,
  input  wire                             scalar_wready ,
  output wire [C_SCALAR_DATA_WIDTH-1:0]   scalar_wdata  ,
  output wire [C_SCALAR_DATA_WIDTH/8-1:0] scalar_wstrb  ,
  output wire                             scalar_wlast  ,
  input  wire                             scalar_bvalid ,
  output wire                             scalar_bready ,
  output wire                             scalar_arvalid,
  input  wire                             scalar_arready,
  output wire [C_SCALAR_ADDR_WIDTH-1:0]   scalar_araddr ,
  output wire [8-1:0]                     scalar_arlen  ,
  input  wire                             scalar_rvalid ,
  output wire                             scalar_rready ,
  input  wire [C_SCALAR_DATA_WIDTH-1:0]   scalar_rdata  ,
  input  wire                             scalar_rlast  ,
  // AXI4 master interface result
  output wire                             result_awvalid,
  input  wire                             result_awready,
  output wire [C_RESULT_ADDR_WIDTH-1:0]   result_awaddr ,
  output wire [8-1:0]                     result_awlen  ,
  output wire                             result_wvalid ,
  input  wire                             result_wready ,
  output wire [C_RESULT_DATA_WIDTH-1:0]   result_wdata  ,
  output wire [C_RESULT_DATA_WIDTH/8-1:0] result_wstrb  ,
  output wire                             result_wlast  ,
  input  wire                             result_bvalid ,
  output wire                             result_bready ,
  output wire                             result_arvalid,
  input  wire                             result_arready,
  output wire [C_RESULT_ADDR_WIDTH-1:0]   result_araddr ,
  output wire [8-1:0]                     result_arlen  ,
  input  wire                             result_rvalid ,
  output wire                             result_rready ,
  input  wire [C_RESULT_DATA_WIDTH-1:0]   result_rdata  ,
  input  wire                             result_rlast  ,
  // Control Signals
  input  wire                             ap_start      ,
  output wire                             ap_idle       ,
  output wire                             ap_done       ,
  output wire                             ap_ready      ,
  input  wire [64-1:0]                    num_in        ,
  input  wire [64-1:0]                    point_p       ,
  input  wire [64-1:0]                    scalar_p      ,
  input  wire [64-1:0]                    result_p      
);


timeunit 1ps;
timeprecision 1ps;

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////
// Large enough for interesting traffic.
localparam integer  LP_DEFAULT_LENGTH_IN_BYTES = 16384;
localparam integer  LP_NUM_EXAMPLES    = 1;

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* KEEP = "yes" *)
logic                                areset                         = 1'b0;
logic                                ap_start_r                     = 1'b0;
logic                                ap_idle_r                      = 1'b1;
logic                                ap_start_pulse                ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_i                     ;
logic [LP_NUM_EXAMPLES-1:0]          ap_done_r                      = {LP_NUM_EXAMPLES{1'b0}};
logic [32-1:0]                       ctrl_constant                  = 32'd1;
logic [63:0] num_in_r;
logic [63:0] point_bytes, scalar_bytes;

///////////////////////////////////////////////////////////////////////////////
// Begin RTL
///////////////////////////////////////////////////////////////////////////////

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

// create pulse when ap_start transitions to 1
always @(posedge ap_clk) begin
  begin
    ap_start_r <= ap_start;
    num_in_r <= num_in;
    scalar_bytes <= num_in * 32;
    point_bytes <= num_in * 64;
  end
end

assign ap_start_pulse = ap_start & ~ap_start_r;

// ap_idle is asserted when done is asserted, it is de-asserted when ap_start_pulse
// is asserted
always @(posedge ap_clk) begin
  if (areset) begin
    ap_idle_r <= 1'b1;
  end
  else begin
    ap_idle_r <= ap_done ? 1'b1 :
      ap_start_pulse ? 1'b0 : ap_idle;
  end
end

assign ap_idle = ap_idle_r;

// Done logic
always @(posedge ap_clk) begin
  if (areset) begin
    ap_done_r <= '0;
  end
  else begin
    ap_done_r <= (ap_done) ? '0 : ap_done_r | ap_done_i;
  end
end

assign ap_done = &ap_done_r;

// Ready Logic (non-pipelined case)
assign ap_ready = ap_done;

if_axi_stream #(.DAT_BITS(C_POINT_DATA_WIDTH), .CTL_BITS(1)) point_if (ap_clk);
if_axi_stream #(.DAT_BITS(C_POINT_DATA_WIDTH), .CTL_BITS(1)) res_if (ap_clk);
if_axi_stream #(.DAT_BITS(C_SCALAR_DATA_WIDTH), .CTL_BITS(1)) scalar_if (ap_clk);

localparam integer LP_SCALAR_DW_BYTES             = C_SCALAR_DATA_WIDTH/8;
localparam integer LP_SCALAR_AXI_BURST_LEN        = 4096/LP_SCALAR_DW_BYTES < 256 ? 4096/LP_SCALAR_DW_BYTES : 256;
localparam integer LP_SCALAR_LOG_BURST_LEN        = $clog2(LP_SCALAR_AXI_BURST_LEN);
localparam integer LP_SCALAR_BRAM_DEPTH           = 512;
localparam integer LP_SCALAR_RD_MAX_OUTSTANDING   = LP_SCALAR_BRAM_DEPTH / LP_SCALAR_AXI_BURST_LEN;
localparam integer LP_SCALAR_WR_MAX_OUTSTANDING   = 32;

localparam integer LP_POINT_DW_BYTES             = C_POINT_DATA_WIDTH/8;
localparam integer LP_POINT_AXI_BURST_LEN        = 4096/LP_POINT_DW_BYTES < 256 ? 4096/LP_POINT_DW_BYTES : 256;
localparam integer LP_POINT_LOG_BURST_LEN        = $clog2(LP_POINT_AXI_BURST_LEN);
localparam integer LP_POINT_BRAM_DEPTH           = 512;
localparam integer LP_POINT_RD_MAX_OUTSTANDING   = LP_POINT_BRAM_DEPTH / LP_POINT_AXI_BURST_LEN;
localparam integer LP_POINT_WR_MAX_OUTSTANDING   = 32;

localparam integer LP_RESULT_DW_BYTES             = C_RESULT_DATA_WIDTH/8;
localparam integer LP_RESULT_AXI_BURST_LEN        = 4096/LP_RESULT_DW_BYTES < 256 ? 4096/LP_RESULT_DW_BYTES : 256;
localparam integer LP_RESULT_LOG_BURST_LEN        = $clog2(LP_RESULT_AXI_BURST_LEN);
localparam integer LP_RESULT_BRAM_DEPTH           = 512;
localparam integer LP_RESULT_RD_MAX_OUTSTANDING   = LP_RESULT_BRAM_DEPTH / LP_RESULT_AXI_BURST_LEN;
localparam integer LP_RESULT_WR_MAX_OUTSTANDING   = 32;


// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
multiexp_kernel_example_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_SCALAR_ADDR_WIDTH          ),
  .C_M_AXI_DATA_WIDTH  ( C_SCALAR_DATA_WIDTH          ),
  .C_XFER_SIZE_WIDTH   ( 32                           ),
  .C_MAX_OUTSTANDING   ( LP_SCALAR_RD_MAX_OUTSTANDING ),
  .C_INCLUDE_DATA_FIFO ( 1                            ),
  .KEY_BITS            ( 256                          )
)
scalar_example_axi_read_master (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .ctrl_start              ( ap_start_pulse          ),
  .ctrl_done               (                         ),
  .ctrl_addr_offset        ( scalar_p                ),
  .ctrl_xfer_size_in_bytes ( scalar_bytes            ),
  .m_axi_arvalid           ( scalar_arvalid          ),
  .m_axi_arready           ( scalar_arready          ),
  .m_axi_araddr            ( scalar_araddr           ),
  .m_axi_arlen             ( scalar_arlen            ),
  .m_axi_rvalid            ( scalar_rvalid           ),
  .m_axi_rready            ( scalar_rready           ),
  .m_axi_rdata             ( scalar_rdata            ),
  .m_axi_rlast             ( scalar_rlast            ),
  .m_axis_aclk             ( ap_clk                  ),
  .m_axis_areset           ( areset                  ),
  .m_axis_tvalid           ( scalar_if.val           ),
  .m_axis_tready           ( scalar_if.rdy           ),
  .m_axis_tlast            ( scalar_if.eop           ),
  .m_axis_tdata            ( scalar_if.dat           )
);

always_comb begin
  scalar_if.sop = 0;
  scalar_if.ctl = 0;
  scalar_if.mod = 0;
  scalar_if.err = 0;
end

assign scalar_awvalid = 0;
assign scalar_awaddr = 0;
assign scalar_awlen = 0;
assign scalar_wvalid = 0;
assign scalar_wdata = 0;
assign scalar_wstrb = 0;
assign scalar_wlast = 0;
assign scalar_bready = 0;

// AXI4 Read Master, output format is an AXI4-Stream master, one stream per thread.
multiexp_kernel_example_axi_read_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_POINT_ADDR_WIDTH          ),
  .C_M_AXI_DATA_WIDTH  ( C_POINT_DATA_WIDTH          ),
  .C_XFER_SIZE_WIDTH   ( 64                          ),
  .C_MAX_OUTSTANDING   ( LP_POINT_RD_MAX_OUTSTANDING ),
  .C_INCLUDE_DATA_FIFO ( 1                           ),
  .KEY_BITS            ( 256                         )
)
point_axi_read_master (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .ctrl_start              ( ap_start_pulse          ),
  .ctrl_done               (                         ),
  .ctrl_addr_offset        ( point_p                 ),
  .ctrl_xfer_size_in_bytes ( point_bytes             ),
  .m_axi_arvalid           ( point_arvalid           ),
  .m_axi_arready           ( point_arready           ),
  .m_axi_araddr            ( point_araddr            ),
  .m_axi_arlen             ( point_arlen             ),
  .m_axi_rvalid            ( point_rvalid            ),
  .m_axi_rready            ( point_rready            ),
  .m_axi_rdata             ( point_rdata             ),
  .m_axi_rlast             ( point_rlast             ),
  .m_axis_aclk             ( ap_clk                  ),
  .m_axis_areset           ( areset                  ),
  .m_axis_tvalid           ( point_if.val            ),
  .m_axis_tready           ( point_if.rdy            ),
  .m_axis_tlast            ( point_if.eop            ),
  .m_axis_tdata            ( point_if.dat            )
);

always_comb begin
  point_if.sop = 0;
  point_if.ctl = 0;
  point_if.mod = 0;
  point_if.err = 0;
end

assign point_awvalid = 0;
assign point_awaddr = 0;
assign point_awlen = 0;
assign point_wvalid = 0;
assign point_wdata = 0;
assign point_wstrb = 0;
assign point_wlast = 0;
assign point_bready = 0;

bn128_multiexp_wrapper bn128_multiexp_wrapper
(
  .i_clk ( ap_clk ),
  .i_rst ( areset ),
  .i_num_in ( num_in_r ),
  .i_scl_if ( scalar_if ),
  .i_pnt_if ( point_if  ),
  .o_res_if ( res_if    )
);

// AXI4 Write Master
multiexp_kernel_example_axi_write_master #(
  .C_M_AXI_ADDR_WIDTH  ( C_RESULT_ADDR_WIDTH          ),
  .C_M_AXI_DATA_WIDTH  ( C_RESULT_DATA_WIDTH          ),
  .C_XFER_SIZE_WIDTH   ( 64                          ),
  .C_MAX_OUTSTANDING   ( LP_RESULT_WR_MAX_OUTSTANDING ),
  .C_INCLUDE_DATA_FIFO ( 1                           )
)
result_axi_write_master (
  .aclk                    ( ap_clk                  ),
  .areset                  ( areset                  ),
  .ctrl_start              ( ap_start_pulse          ),
  .ctrl_done               ( ap_done_i               ),
  .ctrl_addr_offset        ( result_p                ),
  .ctrl_xfer_size_in_bytes ( 96                      ), // Point result
  .m_axi_awvalid           ( result_awvalid          ),
  .m_axi_awready           ( result_awready          ),
  .m_axi_awaddr            ( result_awaddr           ),
  .m_axi_awlen             ( result_awlen            ),
  .m_axi_wvalid            ( result_wvalid           ),
  .m_axi_wready            ( result_wready           ),
  .m_axi_wdata             ( result_wdata            ),
  .m_axi_wstrb             ( result_wstrb            ),
  .m_axi_wlast             ( result_wlast            ),
  .m_axi_bvalid            ( result_bvalid           ),
  .m_axi_bready            ( result_bready           ),
  .s_axis_aclk             ( ap_clk                  ),
  .s_axis_areset           ( areset                  ),
  .s_axis_tvalid           ( res_if.val              ),
  .s_axis_tready           ( res_if.rdy              ),
  .s_axis_tdata            ( res_if.dat              )
);

assign result_arvalid = 0;
assign result_araddr = 0;
assign result_arlen = 0;
assign result_rready = 0;


endmodule : multiexp_kernel_example
`default_nettype wire
