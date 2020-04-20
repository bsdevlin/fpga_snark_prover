// This is a generated file. Use and modify at your own risk.
//////////////////////////////////////////////////////////////////////////////// 
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ns / 1 ps
// Top level of the kernel. Do not modify module name, parameters or ports.
module multiexp_g2_kernel #(
  parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12 ,
  parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32 ,
  parameter integer C_POINT_ADDR_WIDTH         = 64 ,
  parameter integer C_POINT_DATA_WIDTH         = 512,
  parameter integer C_SCALAR_ADDR_WIDTH        = 64 ,
  parameter integer C_SCALAR_DATA_WIDTH        = 256,
  parameter integer C_RESULT_ADDR_WIDTH        = 64 ,
  parameter integer C_RESULT_DATA_WIDTH        = 512
)
(
  // System Signals
  input  wire                                    ap_clk               ,
  input  wire                                    ap_rst_n             ,
  //  Note: A minimum subset of AXI4 memory mapped signals are declared.  AXI
  // signals omitted from these interfaces are automatically inferred with the
  // optimal values for Xilinx accleration platforms.  This allows Xilinx AXI4 Interconnects
  // within the system to be optimized by removing logic for AXI4 protocol
  // features that are not necessary. When adapting AXI4 masters within the RTL
  // kernel that have signals not declared below, it is suitable to add the
  // signals to the declarations below to connect them to the AXI4 Master.
  // 
  // List of ommited signals - effect
  // -------------------------------
  // ID - Transaction ID are used for multithreading and out of order
  // transactions.  This increases complexity. This saves logic and increases Fmax
  // in the system when ommited.
  // SIZE - Default value is log2(data width in bytes). Needed for subsize bursts.
  // This saves logic and increases Fmax in the system when ommited.
  // BURST - Default value (0b01) is incremental.  Wrap and fixed bursts are not
  // recommended. This saves logic and increases Fmax in the system when ommited.
  // LOCK - Not supported in AXI4
  // CACHE - Default value (0b0011) allows modifiable transactions. No benefit to
  // changing this.
  // PROT - Has no effect in current acceleration platforms.
  // QOS - Has no effect in current acceleration platforms.
  // REGION - Has no effect in current acceleration platforms.
  // USER - Has no effect in current acceleration platforms.
  // RESP - Not useful in most acceleration platforms.
  // 
  // AXI4 master interface point
  output wire                                    point_awvalid        ,
  input  wire                                    point_awready        ,
  output wire [C_POINT_ADDR_WIDTH-1:0]           point_awaddr         ,
  output wire [8-1:0]                            point_awlen          ,
  output wire                                    point_wvalid         ,
  input  wire                                    point_wready         ,
  output wire [C_POINT_DATA_WIDTH-1:0]           point_wdata          ,
  output wire [C_POINT_DATA_WIDTH/8-1:0]         point_wstrb          ,
  output wire                                    point_wlast          ,
  input  wire                                    point_bvalid         ,
  output wire                                    point_bready         ,
  output wire                                    point_arvalid        ,
  input  wire                                    point_arready        ,
  output wire [C_POINT_ADDR_WIDTH-1:0]           point_araddr         ,
  output wire [8-1:0]                            point_arlen          ,
  input  wire                                    point_rvalid         ,
  output wire                                    point_rready         ,
  input  wire [C_POINT_DATA_WIDTH-1:0]           point_rdata          ,
  input  wire                                    point_rlast          ,
  // AXI4 master interface scalar
  output wire                                    scalar_awvalid       ,
  input  wire                                    scalar_awready       ,
  output wire [C_SCALAR_ADDR_WIDTH-1:0]          scalar_awaddr        ,
  output wire [8-1:0]                            scalar_awlen         ,
  output wire                                    scalar_wvalid        ,
  input  wire                                    scalar_wready        ,
  output wire [C_SCALAR_DATA_WIDTH-1:0]          scalar_wdata         ,
  output wire [C_SCALAR_DATA_WIDTH/8-1:0]        scalar_wstrb         ,
  output wire                                    scalar_wlast         ,
  input  wire                                    scalar_bvalid        ,
  output wire                                    scalar_bready        ,
  output wire                                    scalar_arvalid       ,
  input  wire                                    scalar_arready       ,
  output wire [C_SCALAR_ADDR_WIDTH-1:0]          scalar_araddr        ,
  output wire [8-1:0]                            scalar_arlen         ,
  input  wire                                    scalar_rvalid        ,
  output wire                                    scalar_rready        ,
  input  wire [C_SCALAR_DATA_WIDTH-1:0]          scalar_rdata         ,
  input  wire                                    scalar_rlast         ,
  // AXI4 master interface result
  output wire                                    result_awvalid       ,
  input  wire                                    result_awready       ,
  output wire [C_RESULT_ADDR_WIDTH-1:0]          result_awaddr        ,
  output wire [8-1:0]                            result_awlen         ,
  output wire                                    result_wvalid        ,
  input  wire                                    result_wready        ,
  output wire [C_RESULT_DATA_WIDTH-1:0]          result_wdata         ,
  output wire [C_RESULT_DATA_WIDTH/8-1:0]        result_wstrb         ,
  output wire                                    result_wlast         ,
  input  wire                                    result_bvalid        ,
  output wire                                    result_bready        ,
  output wire                                    result_arvalid       ,
  input  wire                                    result_arready       ,
  output wire [C_RESULT_ADDR_WIDTH-1:0]          result_araddr        ,
  output wire [8-1:0]                            result_arlen         ,
  input  wire                                    result_rvalid        ,
  output wire                                    result_rready        ,
  input  wire [C_RESULT_DATA_WIDTH-1:0]          result_rdata         ,
  input  wire                                    result_rlast         ,
  // AXI4-Lite slave interface
  input  wire                                    s_axi_control_awvalid,
  output wire                                    s_axi_control_awready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_awaddr ,
  input  wire                                    s_axi_control_wvalid ,
  output wire                                    s_axi_control_wready ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_wdata  ,
  input  wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb  ,
  input  wire                                    s_axi_control_arvalid,
  output wire                                    s_axi_control_arready,
  input  wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0]   s_axi_control_araddr ,
  output wire                                    s_axi_control_rvalid ,
  input  wire                                    s_axi_control_rready ,
  output wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0]   s_axi_control_rdata  ,
  output wire [2-1:0]                            s_axi_control_rresp  ,
  output wire                                    s_axi_control_bvalid ,
  input  wire                                    s_axi_control_bready ,
  output wire [2-1:0]                            s_axi_control_bresp  ,
  output wire                                    interrupt            
);

///////////////////////////////////////////////////////////////////////////////
// Local Parameters
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// Wires and Variables
///////////////////////////////////////////////////////////////////////////////
(* DONT_TOUCH = "yes" *)
reg                                 areset                         = 1'b0;
wire                                ap_start                      ;
wire                                ap_idle                       ;
wire                                ap_done                       ;
wire                                ap_ready                      ;
wire [64-1:0]                       num_in                        ;
wire [64-1:0]                       point_p                       ;
wire [64-1:0]                       scalar_p                      ;
wire [64-1:0]                       result_p                      ;

// Register and invert reset signal.
always @(posedge ap_clk) begin
  areset <= ~ap_rst_n;
end

///////////////////////////////////////////////////////////////////////////////
// Begin control interface RTL.  Modifying not recommended.
///////////////////////////////////////////////////////////////////////////////


// AXI4-Lite slave interface
multiexp_g2_kernel_control_s_axi #(
  .C_S_AXI_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH )
)
inst_control_s_axi (
  .ACLK      ( ap_clk                ),
  .ARESET    ( areset                ),
  .ACLK_EN   ( 1'b1                  ),
  .AWVALID   ( s_axi_control_awvalid ),
  .AWREADY   ( s_axi_control_awready ),
  .AWADDR    ( s_axi_control_awaddr  ),
  .WVALID    ( s_axi_control_wvalid  ),
  .WREADY    ( s_axi_control_wready  ),
  .WDATA     ( s_axi_control_wdata   ),
  .WSTRB     ( s_axi_control_wstrb   ),
  .ARVALID   ( s_axi_control_arvalid ),
  .ARREADY   ( s_axi_control_arready ),
  .ARADDR    ( s_axi_control_araddr  ),
  .RVALID    ( s_axi_control_rvalid  ),
  .RREADY    ( s_axi_control_rready  ),
  .RDATA     ( s_axi_control_rdata   ),
  .RRESP     ( s_axi_control_rresp   ),
  .BVALID    ( s_axi_control_bvalid  ),
  .BREADY    ( s_axi_control_bready  ),
  .BRESP     ( s_axi_control_bresp   ),
  .interrupt ( interrupt             ),
  .ap_start  ( ap_start              ),
  .ap_done   ( ap_done               ),
  .ap_ready  ( ap_ready              ),
  .ap_idle   ( ap_idle               ),
  .num_in    ( num_in                ),
  .point_p   ( point_p               ),
  .scalar_p  ( scalar_p              ),
  .result_p  ( result_p              )
);

///////////////////////////////////////////////////////////////////////////////
// Add kernel logic here.  Modify/remove example code as necessary.
///////////////////////////////////////////////////////////////////////////////

// Example RTL block.  Remove to insert custom logic.
multiexp_g2_kernel_example #(
  .C_POINT_ADDR_WIDTH  ( C_POINT_ADDR_WIDTH  ),
  .C_POINT_DATA_WIDTH  ( C_POINT_DATA_WIDTH  ),
  .C_SCALAR_ADDR_WIDTH ( C_SCALAR_ADDR_WIDTH ),
  .C_SCALAR_DATA_WIDTH ( C_SCALAR_DATA_WIDTH ),
  .C_RESULT_ADDR_WIDTH ( C_RESULT_ADDR_WIDTH ),
  .C_RESULT_DATA_WIDTH ( C_RESULT_DATA_WIDTH )
)
inst_example (
  .ap_clk         ( ap_clk         ),
  .ap_rst_n       ( ap_rst_n       ),
  .point_awvalid  ( point_awvalid  ),
  .point_awready  ( point_awready  ),
  .point_awaddr   ( point_awaddr   ),
  .point_awlen    ( point_awlen    ),
  .point_wvalid   ( point_wvalid   ),
  .point_wready   ( point_wready   ),
  .point_wdata    ( point_wdata    ),
  .point_wstrb    ( point_wstrb    ),
  .point_wlast    ( point_wlast    ),
  .point_bvalid   ( point_bvalid   ),
  .point_bready   ( point_bready   ),
  .point_arvalid  ( point_arvalid  ),
  .point_arready  ( point_arready  ),
  .point_araddr   ( point_araddr   ),
  .point_arlen    ( point_arlen    ),
  .point_rvalid   ( point_rvalid   ),
  .point_rready   ( point_rready   ),
  .point_rdata    ( point_rdata    ),
  .point_rlast    ( point_rlast    ),
  .scalar_awvalid ( scalar_awvalid ),
  .scalar_awready ( scalar_awready ),
  .scalar_awaddr  ( scalar_awaddr  ),
  .scalar_awlen   ( scalar_awlen   ),
  .scalar_wvalid  ( scalar_wvalid  ),
  .scalar_wready  ( scalar_wready  ),
  .scalar_wdata   ( scalar_wdata   ),
  .scalar_wstrb   ( scalar_wstrb   ),
  .scalar_wlast   ( scalar_wlast   ),
  .scalar_bvalid  ( scalar_bvalid  ),
  .scalar_bready  ( scalar_bready  ),
  .scalar_arvalid ( scalar_arvalid ),
  .scalar_arready ( scalar_arready ),
  .scalar_araddr  ( scalar_araddr  ),
  .scalar_arlen   ( scalar_arlen   ),
  .scalar_rvalid  ( scalar_rvalid  ),
  .scalar_rready  ( scalar_rready  ),
  .scalar_rdata   ( scalar_rdata   ),
  .scalar_rlast   ( scalar_rlast   ),
  .result_awvalid ( result_awvalid ),
  .result_awready ( result_awready ),
  .result_awaddr  ( result_awaddr  ),
  .result_awlen   ( result_awlen   ),
  .result_wvalid  ( result_wvalid  ),
  .result_wready  ( result_wready  ),
  .result_wdata   ( result_wdata   ),
  .result_wstrb   ( result_wstrb   ),
  .result_wlast   ( result_wlast   ),
  .result_bvalid  ( result_bvalid  ),
  .result_bready  ( result_bready  ),
  .result_arvalid ( result_arvalid ),
  .result_arready ( result_arready ),
  .result_araddr  ( result_araddr  ),
  .result_arlen   ( result_arlen   ),
  .result_rvalid  ( result_rvalid  ),
  .result_rready  ( result_rready  ),
  .result_rdata   ( result_rdata   ),
  .result_rlast   ( result_rlast   ),
  .ap_start       ( ap_start       ),
  .ap_done        ( ap_done        ),
  .ap_idle        ( ap_idle        ),
  .ap_ready       ( ap_ready       ),
  .num_in         ( num_in         ),
  .point_p        ( point_p        ),
  .scalar_p       ( scalar_p       ),
  .result_p       ( result_p       )
);

endmodule
`default_nettype wire
