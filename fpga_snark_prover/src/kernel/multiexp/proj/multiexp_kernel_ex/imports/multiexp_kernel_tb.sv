// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////
// default_nettype of none prevents implicit wire declaration.
`default_nettype none
`timescale 1 ps / 1 ps
import axi_vip_pkg::*;
import slv_point_vip_pkg::*;
import slv_scalar_vip_pkg::*;
import slv_result_vip_pkg::*;
import control_multiexp_kernel_vip_pkg::*;

module multiexp_kernel_tb ();
parameter integer LP_MAX_LENGTH = 8192;
parameter integer LP_MAX_TRANSFER_LENGTH = 16384 / 4;
parameter integer C_S_AXI_CONTROL_ADDR_WIDTH = 12;
parameter integer C_S_AXI_CONTROL_DATA_WIDTH = 32;
parameter integer C_POINT_ADDR_WIDTH = 64;
parameter integer C_POINT_DATA_WIDTH = 512;
parameter integer C_SCALAR_ADDR_WIDTH = 64;
parameter integer C_SCALAR_DATA_WIDTH = 256;
parameter integer C_RESULT_ADDR_WIDTH = 64;
parameter integer C_RESULT_DATA_WIDTH = 512;

// Control Register
parameter KRNL_CTRL_REG_ADDR     = 32'h00000000;
parameter CTRL_START_MASK        = 32'h00000001;
parameter CTRL_DONE_MASK         = 32'h00000002;
parameter CTRL_IDLE_MASK         = 32'h00000004;
parameter CTRL_READY_MASK        = 32'h00000008;
parameter CTRL_CONTINUE_MASK     = 32'h00000010; // Only ap_ctrl_chain
parameter CTRL_AUTO_RESTART_MASK = 32'h00000080; // Not used

// Global Interrupt Enable Register
parameter KRNL_GIE_REG_ADDR      = 32'h00000004;
parameter GIE_GIE_MASK           = 32'h00000001;
// IP Interrupt Enable Register
parameter KRNL_IER_REG_ADDR      = 32'h00000008;
parameter IER_DONE_MASK          = 32'h00000001;
parameter IER_READY_MASK         = 32'h00000002;
// IP Interrupt Status Register
parameter KRNL_ISR_REG_ADDR      = 32'h0000000c;
parameter ISR_DONE_MASK          = 32'h00000001;
parameter ISR_READY_MASK         = 32'h00000002;

parameter integer LP_CLK_PERIOD_PS = 4000; // 250 MHz

parameter NUM_IN = 4;

//System Signals
logic ap_clk = 0;

initial begin: AP_CLK
  forever begin
    ap_clk = #(LP_CLK_PERIOD_PS/2) ~ap_clk;
  end
end
 
//System Signals
logic ap_rst_n = 0;
logic initial_reset  =0;

task automatic ap_rst_n_sequence(input integer unsigned width = 20);
  @(posedge ap_clk);
  #1ps;
  ap_rst_n = 0;
  repeat (width) @(posedge ap_clk);
  #1ps;
  ap_rst_n = 1;
endtask

initial begin: AP_RST
  ap_rst_n_sequence(50);
  initial_reset =1;
end
//AXI4 master interface point
wire [1-1:0] point_awvalid;
wire [1-1:0] point_awready;
wire [C_POINT_ADDR_WIDTH-1:0] point_awaddr;
wire [8-1:0] point_awlen;
wire [1-1:0] point_wvalid;
wire [1-1:0] point_wready;
wire [C_POINT_DATA_WIDTH-1:0] point_wdata;
wire [C_POINT_DATA_WIDTH/8-1:0] point_wstrb;
wire [1-1:0] point_wlast;
wire [1-1:0] point_bvalid;
wire [1-1:0] point_bready;
wire [1-1:0] point_arvalid;
wire [1-1:0] point_arready;
wire [C_POINT_ADDR_WIDTH-1:0] point_araddr;
wire [8-1:0] point_arlen;
wire [1-1:0] point_rvalid;
wire [1-1:0] point_rready;
wire [C_POINT_DATA_WIDTH-1:0] point_rdata;
wire [1-1:0] point_rlast;
//AXI4 master interface scalar
wire [1-1:0] scalar_awvalid;
wire [1-1:0] scalar_awready;
wire [C_SCALAR_ADDR_WIDTH-1:0] scalar_awaddr;
wire [8-1:0] scalar_awlen;
wire [1-1:0] scalar_wvalid;
wire [1-1:0] scalar_wready;
wire [C_SCALAR_DATA_WIDTH-1:0] scalar_wdata;
wire [C_SCALAR_DATA_WIDTH/8-1:0] scalar_wstrb;
wire [1-1:0] scalar_wlast;
wire [1-1:0] scalar_bvalid;
wire [1-1:0] scalar_bready;
wire [1-1:0] scalar_arvalid;
wire [1-1:0] scalar_arready;
wire [C_SCALAR_ADDR_WIDTH-1:0] scalar_araddr;
wire [8-1:0] scalar_arlen;
wire [1-1:0] scalar_rvalid;
wire [1-1:0] scalar_rready;
wire [C_SCALAR_DATA_WIDTH-1:0] scalar_rdata;
wire [1-1:0] scalar_rlast;
//AXI4 master interface result
wire [1-1:0] result_awvalid;
wire [1-1:0] result_awready;
wire [C_RESULT_ADDR_WIDTH-1:0] result_awaddr;
wire [8-1:0] result_awlen;
wire [1-1:0] result_wvalid;
wire [1-1:0] result_wready;
wire [C_RESULT_DATA_WIDTH-1:0] result_wdata;
wire [C_RESULT_DATA_WIDTH/8-1:0] result_wstrb;
wire [1-1:0] result_wlast;
wire [1-1:0] result_bvalid;
wire [1-1:0] result_bready;
wire [1-1:0] result_arvalid;
wire [1-1:0] result_arready;
wire [C_RESULT_ADDR_WIDTH-1:0] result_araddr;
wire [8-1:0] result_arlen;
wire [1-1:0] result_rvalid;
wire [1-1:0] result_rready;
wire [C_RESULT_DATA_WIDTH-1:0] result_rdata;
wire [1-1:0] result_rlast;
//AXI4LITE control signals
wire [1-1:0] s_axi_control_awvalid;
wire [1-1:0] s_axi_control_awready;
wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0] s_axi_control_awaddr;
wire [1-1:0] s_axi_control_wvalid;
wire [1-1:0] s_axi_control_wready;
wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0] s_axi_control_wdata;
wire [C_S_AXI_CONTROL_DATA_WIDTH/8-1:0] s_axi_control_wstrb;
wire [1-1:0] s_axi_control_arvalid;
wire [1-1:0] s_axi_control_arready;
wire [C_S_AXI_CONTROL_ADDR_WIDTH-1:0] s_axi_control_araddr;
wire [1-1:0] s_axi_control_rvalid;
wire [1-1:0] s_axi_control_rready;
wire [C_S_AXI_CONTROL_DATA_WIDTH-1:0] s_axi_control_rdata;
wire [2-1:0] s_axi_control_rresp;
wire [1-1:0] s_axi_control_bvalid;
wire [1-1:0] s_axi_control_bready;
wire [2-1:0] s_axi_control_bresp;
wire interrupt;

// DUT instantiation
multiexp_kernel #(
  .C_S_AXI_CONTROL_ADDR_WIDTH ( C_S_AXI_CONTROL_ADDR_WIDTH ),
  .C_S_AXI_CONTROL_DATA_WIDTH ( C_S_AXI_CONTROL_DATA_WIDTH ),
  .C_POINT_ADDR_WIDTH         ( C_POINT_ADDR_WIDTH         ),
  .C_POINT_DATA_WIDTH         ( C_POINT_DATA_WIDTH         ),
  .C_SCALAR_ADDR_WIDTH        ( C_SCALAR_ADDR_WIDTH        ),
  .C_SCALAR_DATA_WIDTH        ( C_SCALAR_DATA_WIDTH        ),
  .C_RESULT_ADDR_WIDTH        ( C_RESULT_ADDR_WIDTH        ),
  .C_RESULT_DATA_WIDTH        ( C_RESULT_DATA_WIDTH        )
)
inst_dut (
  .ap_clk                ( ap_clk                ),
  .ap_rst_n              ( ap_rst_n              ),
  .point_awvalid         ( point_awvalid         ),
  .point_awready         ( point_awready         ),
  .point_awaddr          ( point_awaddr          ),
  .point_awlen           ( point_awlen           ),
  .point_wvalid          ( point_wvalid          ),
  .point_wready          ( point_wready          ),
  .point_wdata           ( point_wdata           ),
  .point_wstrb           ( point_wstrb           ),
  .point_wlast           ( point_wlast           ),
  .point_bvalid          ( point_bvalid          ),
  .point_bready          ( point_bready          ),
  .point_arvalid         ( point_arvalid         ),
  .point_arready         ( point_arready         ),
  .point_araddr          ( point_araddr          ),
  .point_arlen           ( point_arlen           ),
  .point_rvalid          ( point_rvalid          ),
  .point_rready          ( point_rready          ),
  .point_rdata           ( point_rdata           ),
  .point_rlast           ( point_rlast           ),
  .scalar_awvalid        ( scalar_awvalid        ),
  .scalar_awready        ( scalar_awready        ),
  .scalar_awaddr         ( scalar_awaddr         ),
  .scalar_awlen          ( scalar_awlen          ),
  .scalar_wvalid         ( scalar_wvalid         ),
  .scalar_wready         ( scalar_wready         ),
  .scalar_wdata          ( scalar_wdata          ),
  .scalar_wstrb          ( scalar_wstrb          ),
  .scalar_wlast          ( scalar_wlast          ),
  .scalar_bvalid         ( scalar_bvalid         ),
  .scalar_bready         ( scalar_bready         ),
  .scalar_arvalid        ( scalar_arvalid        ),
  .scalar_arready        ( scalar_arready        ),
  .scalar_araddr         ( scalar_araddr         ),
  .scalar_arlen          ( scalar_arlen          ),
  .scalar_rvalid         ( scalar_rvalid         ),
  .scalar_rready         ( scalar_rready         ),
  .scalar_rdata          ( scalar_rdata          ),
  .scalar_rlast          ( scalar_rlast          ),
  .result_awvalid        ( result_awvalid        ),
  .result_awready        ( result_awready        ),
  .result_awaddr         ( result_awaddr         ),
  .result_awlen          ( result_awlen          ),
  .result_wvalid         ( result_wvalid         ),
  .result_wready         ( result_wready         ),
  .result_wdata          ( result_wdata          ),
  .result_wstrb          ( result_wstrb          ),
  .result_wlast          ( result_wlast          ),
  .result_bvalid         ( result_bvalid         ),
  .result_bready         ( result_bready         ),
  .result_arvalid        ( result_arvalid        ),
  .result_arready        ( result_arready        ),
  .result_araddr         ( result_araddr         ),
  .result_arlen          ( result_arlen          ),
  .result_rvalid         ( result_rvalid         ),
  .result_rready         ( result_rready         ),
  .result_rdata          ( result_rdata          ),
  .result_rlast          ( result_rlast          ),
  .s_axi_control_awvalid ( s_axi_control_awvalid ),
  .s_axi_control_awready ( s_axi_control_awready ),
  .s_axi_control_awaddr  ( s_axi_control_awaddr  ),
  .s_axi_control_wvalid  ( s_axi_control_wvalid  ),
  .s_axi_control_wready  ( s_axi_control_wready  ),
  .s_axi_control_wdata   ( s_axi_control_wdata   ),
  .s_axi_control_wstrb   ( s_axi_control_wstrb   ),
  .s_axi_control_arvalid ( s_axi_control_arvalid ),
  .s_axi_control_arready ( s_axi_control_arready ),
  .s_axi_control_araddr  ( s_axi_control_araddr  ),
  .s_axi_control_rvalid  ( s_axi_control_rvalid  ),
  .s_axi_control_rready  ( s_axi_control_rready  ),
  .s_axi_control_rdata   ( s_axi_control_rdata   ),
  .s_axi_control_rresp   ( s_axi_control_rresp   ),
  .s_axi_control_bvalid  ( s_axi_control_bvalid  ),
  .s_axi_control_bready  ( s_axi_control_bready  ),
  .s_axi_control_bresp   ( s_axi_control_bresp   ),
  .interrupt             ( interrupt             )
);

// Master Control instantiation
control_multiexp_kernel_vip inst_control_multiexp_kernel_vip (
  .aclk          ( ap_clk                ),
  .aresetn       ( ap_rst_n              ),
  .m_axi_awvalid ( s_axi_control_awvalid ),
  .m_axi_awready ( s_axi_control_awready ),
  .m_axi_awaddr  ( s_axi_control_awaddr  ),
  .m_axi_wvalid  ( s_axi_control_wvalid  ),
  .m_axi_wready  ( s_axi_control_wready  ),
  .m_axi_wdata   ( s_axi_control_wdata   ),
  .m_axi_wstrb   ( s_axi_control_wstrb   ),
  .m_axi_arvalid ( s_axi_control_arvalid ),
  .m_axi_arready ( s_axi_control_arready ),
  .m_axi_araddr  ( s_axi_control_araddr  ),
  .m_axi_rvalid  ( s_axi_control_rvalid  ),
  .m_axi_rready  ( s_axi_control_rready  ),
  .m_axi_rdata   ( s_axi_control_rdata   ),
  .m_axi_rresp   ( s_axi_control_rresp   ),
  .m_axi_bvalid  ( s_axi_control_bvalid  ),
  .m_axi_bready  ( s_axi_control_bready  ),
  .m_axi_bresp   ( s_axi_control_bresp   )
);

control_multiexp_kernel_vip_mst_t  ctrl;

// Slave MM VIP instantiation
slv_point_vip inst_slv_point_vip (
  .aclk          ( ap_clk        ),
  .aresetn       ( ap_rst_n      ),
  .s_axi_awvalid ( point_awvalid ),
  .s_axi_awready ( point_awready ),
  .s_axi_awaddr  ( point_awaddr  ),
  .s_axi_awlen   ( point_awlen   ),
  .s_axi_wvalid  ( point_wvalid  ),
  .s_axi_wready  ( point_wready  ),
  .s_axi_wdata   ( point_wdata   ),
  .s_axi_wstrb   ( point_wstrb   ),
  .s_axi_wlast   ( point_wlast   ),
  .s_axi_bvalid  ( point_bvalid  ),
  .s_axi_bready  ( point_bready  ),
  .s_axi_arvalid ( point_arvalid ),
  .s_axi_arready ( point_arready ),
  .s_axi_araddr  ( point_araddr  ),
  .s_axi_arlen   ( point_arlen   ),
  .s_axi_rvalid  ( point_rvalid  ),
  .s_axi_rready  ( point_rready  ),
  .s_axi_rdata   ( point_rdata   ),
  .s_axi_rlast   ( point_rlast   )
);


slv_point_vip_slv_mem_t   point;
slv_point_vip_slv_t   point_slv;

// Slave MM VIP instantiation
slv_scalar_vip inst_slv_scalar_vip (
  .aclk          ( ap_clk         ),
  .aresetn       ( ap_rst_n       ),
  .s_axi_awvalid ( scalar_awvalid ),
  .s_axi_awready ( scalar_awready ),
  .s_axi_awaddr  ( scalar_awaddr  ),
  .s_axi_awlen   ( scalar_awlen   ),
  .s_axi_wvalid  ( scalar_wvalid  ),
  .s_axi_wready  ( scalar_wready  ),
  .s_axi_wdata   ( scalar_wdata   ),
  .s_axi_wstrb   ( scalar_wstrb   ),
  .s_axi_wlast   ( scalar_wlast   ),
  .s_axi_bvalid  ( scalar_bvalid  ),
  .s_axi_bready  ( scalar_bready  ),
  .s_axi_arvalid ( scalar_arvalid ),
  .s_axi_arready ( scalar_arready ),
  .s_axi_araddr  ( scalar_araddr  ),
  .s_axi_arlen   ( scalar_arlen   ),
  .s_axi_rvalid  ( scalar_rvalid  ),
  .s_axi_rready  ( scalar_rready  ),
  .s_axi_rdata   ( scalar_rdata   ),
  .s_axi_rlast   ( scalar_rlast   )
);


slv_scalar_vip_slv_mem_t   scalar;
slv_scalar_vip_slv_t   scalar_slv;

// Slave MM VIP instantiation
slv_result_vip inst_slv_result_vip (
  .aclk          ( ap_clk         ),
  .aresetn       ( ap_rst_n       ),
  .s_axi_awvalid ( result_awvalid ),
  .s_axi_awready ( result_awready ),
  .s_axi_awaddr  ( result_awaddr  ),
  .s_axi_awlen   ( result_awlen   ),
  .s_axi_wvalid  ( result_wvalid  ),
  .s_axi_wready  ( result_wready  ),
  .s_axi_wdata   ( result_wdata   ),
  .s_axi_wstrb   ( result_wstrb   ),
  .s_axi_wlast   ( result_wlast   ),
  .s_axi_bvalid  ( result_bvalid  ),
  .s_axi_bready  ( result_bready  ),
  .s_axi_arvalid ( result_arvalid ),
  .s_axi_arready ( result_arready ),
  .s_axi_araddr  ( result_araddr  ),
  .s_axi_arlen   ( result_arlen   ),
  .s_axi_rvalid  ( result_rvalid  ),
  .s_axi_rready  ( result_rready  ),
  .s_axi_rdata   ( result_rdata   ),
  .s_axi_rlast   ( result_rlast   )
);


slv_result_vip_slv_mem_t   result;
slv_result_vip_slv_t   result_slv;

parameter NUM_AXIS_MST = 0;
parameter NUM_AXIS_SLV = 0;

bit               error_found = 0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : point
bit [63:0] point_p_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : scalar
bit [63:0] scalar_p_ptr = 64'h0;

///////////////////////////////////////////////////////////////////////////
// Pointer for interface : result
bit [63:0] result_p_ptr = 64'h0;

/////////////////////////////////////////////////////////////////////////////////////////////////
// Backdoor fill the point memory.
function void point_fill_memory(
  input bit [63:0] ptr,
  input integer    length
);
  for (longint unsigned slot = 0; slot < length; slot++) begin
    point.mem_model.backdoor_memory_write_4byte(ptr + (slot * 4), slot);
  end
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Backdoor fill the scalar memory.
function void scalar_fill_memory(
  input bit [63:0] ptr,
  input integer    length
);
  for (longint unsigned slot = 0; slot < length; slot++) begin
    scalar.mem_model.backdoor_memory_write_4byte(ptr + (slot * 4), slot);
  end
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Backdoor fill the result memory.
function void result_fill_memory(
  input bit [63:0] ptr,
  input integer    length
);
  for (longint unsigned slot = 0; slot < length; slot++) begin
    result.mem_model.backdoor_memory_write_4byte(ptr + (slot * 4), slot);
  end
endfunction

task automatic system_reset_sequence(input integer unsigned width = 20);
  $display("%t : Starting System Reset Sequence", $time);
  fork
    ap_rst_n_sequence(25);
    
  join

endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// Generate a random 32bit number
function bit [31:0] get_random_4bytes();
  bit [31:0] rptr;
  ptr_random_failed: assert(std::randomize(rptr));
  return(rptr);
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Generate a random 64bit 4k aligned address pointer.
function bit [63:0] get_random_ptr();
  bit [63:0] rptr;
  ptr_random_failed: assert(std::randomize(rptr));
  rptr[31:0] &= ~(32'h00000fff);
  return(rptr);
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface non-blocking write
// The task will return when the transaction has been accepted by the driver. It will be some
// amount of time before it will appear on the interface.
task automatic write_register (input bit [31:0] addr_in, input bit [31:0] data);
  axi_transaction   wr_xfer;
  wr_xfer = ctrl.wr_driver.create_transaction("wr_xfer");
  assert(wr_xfer.randomize() with {addr == addr_in;});
  wr_xfer.set_data_beat(0, data);
  ctrl.wr_driver.send(wr_xfer);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking write
// The task will return when the BRESP has been returned from the kernel.
task automatic blocking_write_register (input bit [31:0] addr_in, input bit [31:0] data);
  axi_transaction   wr_xfer;
  axi_transaction   wr_rsp;
  wr_xfer = ctrl.wr_driver.create_transaction("wr_xfer");
  wr_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  assert(wr_xfer.randomize() with {addr == addr_in;});
  wr_xfer.set_data_beat(0, data);
  ctrl.wr_driver.send(wr_xfer);
  ctrl.wr_driver.wait_rsp(wr_rsp);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking read
// The task will return when the BRESP has been returned from the kernel.
task automatic read_register (input bit [31:0] addr, output bit [31:0] rddata);
  axi_transaction   rd_xfer;
  axi_transaction   rd_rsp;
  bit [31:0] rd_value;
  rd_xfer = ctrl.rd_driver.create_transaction("rd_xfer");
  rd_xfer.set_addr(addr);
  rd_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  ctrl.rd_driver.send(rd_xfer);
  ctrl.rd_driver.wait_rsp(rd_rsp);
  rd_value = rd_rsp.get_data_beat(0);
  rddata = rd_value;
endtask



/////////////////////////////////////////////////////////////////////////////////////////////////
// Poll the Control interface status register.
// This will poll until the DONE flag in the status register is asserted.
task automatic poll_done_register ();
  bit [31:0] rd_value;
  do begin
    read_register(KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_DONE_MASK) == 0);
endtask

// This will poll until the IDLE flag in the status register is asserted.
task automatic poll_idle_register ();
  bit [31:0] rd_value;
  do begin
    read_register(KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_IDLE_MASK) == 0);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Write to the control registers to enable the triggering of interrupts for the kernel
task automatic enable_interrupts();
  $display("Starting: Enabling Interrupts....");
  write_register(KRNL_GIE_REG_ADDR, GIE_GIE_MASK);
  write_register(KRNL_IER_REG_ADDR, IER_DONE_MASK);
  $display("Finished: Interrupts enabled.");
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Disabled the interrupts.
task automatic disable_interrupts();
  $display("Starting: Disable Interrupts....");
  write_register(KRNL_GIE_REG_ADDR, 32'h0);
  write_register(KRNL_IER_REG_ADDR, 32'h0);
  $display("Finished: Interrupts disabled.");
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
//When the interrupt is asserted, read the correct registers and clear the asserted interrupt.
task automatic service_interrupts();
  bit [31:0] rd_value;
  $display("Starting Servicing interrupts....");
  read_register(KRNL_CTRL_REG_ADDR, rd_value);
  $display("Control Register: 0x%0x", rd_value);

  blocking_write_register(KRNL_CTRL_REG_ADDR, rd_value);

  if ((rd_value & CTRL_DONE_MASK) == 0) begin
    $error("%t : DONE bit not asserted. Register value: (0x%0x)", $time, rd_value);
  end
  read_register(KRNL_ISR_REG_ADDR, rd_value);
  $display("Interrupt Status Register: 0x%0x", rd_value);
  blocking_write_register(KRNL_ISR_REG_ADDR, rd_value);
  $display("Finished Servicing interrupts");
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Start the control VIP, SLAVE memory models and AXI4-Stream.
task automatic start_vips();
  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Control Master: ctrl");
  ctrl = new("ctrl", multiexp_kernel_tb.inst_control_multiexp_kernel_vip.inst.IF);
  ctrl.start_master();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: point");
  point = new("point", multiexp_kernel_tb.inst_slv_point_vip.inst.IF);
  point.start_slave();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: scalar");
  scalar = new("scalar", multiexp_kernel_tb.inst_slv_scalar_vip.inst.IF);
  scalar.start_slave();

  $display("///////////////////////////////////////////////////////////////////////////");
  $display("Starting Memory slave: result");
  result = new("result", multiexp_kernel_tb.inst_slv_result_vip.inst.IF);
  result.start_slave();

endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the connected slave interfaces, set the Slave to not de-assert WREADY at any time.
// This will show the fastest outbound bandwidth from the WRITE channel.
task automatic slv_no_backpressure_wready();
  axi_ready_gen     rgen;
  $display("%t - Applying slv_no_backpressure_wready", $time);

  rgen = new("point_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  point.wr_driver.set_wready_gen(rgen);

  rgen = new("scalar_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  scalar.wr_driver.set_wready_gen(rgen);

  rgen = new("result_no_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_NO_BACKPRESSURE);
  result.wr_driver.set_wready_gen(rgen);

endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the connected slave interfaces, apply a WREADY policy to introduce backpressure.
// Based on the simulation seed the order/shape of the WREADY per-channel will be different.
task automatic slv_random_backpressure_wready();
  axi_ready_gen     rgen;
  $display("%t - Applying slv_random_backpressure_wready", $time);

  rgen = new("point_random_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
  rgen.set_low_time_range(0,12);
  rgen.set_high_time_range(1,12);
  rgen.set_event_count_range(3,5);
  point.wr_driver.set_wready_gen(rgen);

  rgen = new("scalar_random_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
  rgen.set_low_time_range(0,12);
  rgen.set_high_time_range(1,12);
  rgen.set_event_count_range(3,5);
  scalar.wr_driver.set_wready_gen(rgen);

  rgen = new("result_random_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
  rgen.set_low_time_range(0,12);
  rgen.set_high_time_range(1,12);
  rgen.set_event_count_range(3,5);
  result.wr_driver.set_wready_gen(rgen);

endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the connected slave interfaces, force the memory model to not insert any inter-beat
// gaps on the READ channel.
task automatic slv_no_delay_rvalid();
  $display("%t - Applying slv_no_delay_rvalid", $time);

  point.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  point.mem_model.set_inter_beat_gap(0);

  scalar.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  scalar.mem_model.set_inter_beat_gap(0);

  result.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_FIXED);
  result.mem_model.set_inter_beat_gap(0);

endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the connected slave interfaces, Allow the memory model to insert any inter-beat
// gaps on the READ channel.
task automatic slv_random_delay_rvalid();
  $display("%t - Applying slv_random_delay_rvalid", $time);

  point.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  point.mem_model.set_inter_beat_gap_range(0,10);

  scalar.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  scalar.mem_model.set_inter_beat_gap_range(0,10);

  result.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  result.mem_model.set_inter_beat_gap_range(0,10);

endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Check to ensure, following reset the value of the register is 0.
// Check that only the width of the register bits can be written.
task automatic check_register_value(input bit [31:0] addr_in, input integer unsigned register_width, output bit error_found);
  bit [31:0] rddata;
  bit [31:0] mask_data;
  error_found = 0;
  if (register_width < 32) begin
    mask_data = (1 << register_width) - 1;
  end else begin
    mask_data = 32'hffffffff;
  end
  read_register(addr_in, rddata);
  if (rddata != 32'h0) begin
    $error("Initial value mismatch: A:0x%0x : Expected 0x%x -> Got 0x%x", addr_in, 0, rddata);
    error_found = 1;
  end
  blocking_write_register(addr_in, 32'hffffffff);
  read_register(addr_in, rddata);
  if (rddata != mask_data) begin
    $error("Initial value mismatch: A:0x%0x : Expected 0x%x -> Got 0x%x", addr_in, mask_data, rddata);
    error_found = 1;
  end
endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// For each of the scalar registers, check:
// * reset value
// * correct number bits set on a write
task automatic check_scalar_registers(output bit error_found);
  bit tmp_error_found = 0;
  error_found = 0;
  $display("%t : Checking post reset values of scalar registers", $time);

  ///////////////////////////////////////////////////////////////////////////
  //Check ID 0: num_in (0x010)
  check_register_value(32'h010, 64, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Check ID 0: num_in (0x014)
  check_register_value(32'h014, 32, tmp_error_found);
  error_found |= tmp_error_found;

endtask

task automatic set_scalar_registers();
  $display("%t : Setting Scalar Registers registers", $time);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 0: num_in (0x010) -> 32'hffffffff (scalar)
  write_register(32'h010, NUM_IN[31:0]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 0: num_in (0x014) -> 32'hffffffff (scalar, upper 32 bits)
  write_register(32'h014, NUM_IN[63:32]);

endtask

task automatic check_pointer_registers(output bit error_found);
  bit tmp_error_found = 0;
  ///////////////////////////////////////////////////////////////////////////
  //Check the reset states of the pointer registers.
  $display("%t : Checking post reset values of pointer registers", $time);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 1: point_p (0x01c)
  check_register_value(32'h01c, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 1: point_p (0x020)
  check_register_value(32'h020, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 2: scalar_p (0x028)
  check_register_value(32'h028, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 2: scalar_p (0x02c)
  check_register_value(32'h02c, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 3: result_p (0x034)
  check_register_value(32'h034, 32, tmp_error_found);
  error_found |= tmp_error_found;

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 3: result_p (0x038)
  check_register_value(32'h038, 32, tmp_error_found);
  error_found |= tmp_error_found;

endtask

task automatic set_memory_pointers();
  ///////////////////////////////////////////////////////////////////////////
  //Randomly generate memory pointers.
  point_p_ptr = get_random_ptr();
  scalar_p_ptr = get_random_ptr();
  result_p_ptr = get_random_ptr();

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 1: point_p (0x01c) -> Randomized 4k aligned address (Global memory, lower 32 bits)
  write_register(32'h01c, point_p_ptr[31:0]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 1: point_p (0x020) -> Randomized 4k aligned address (Global memory, upper 32 bits)
  write_register(32'h020, point_p_ptr[63:32]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 2: scalar_p (0x028) -> Randomized 4k aligned address (Global memory, lower 32 bits)
  write_register(32'h028, scalar_p_ptr[31:0]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 2: scalar_p (0x02c) -> Randomized 4k aligned address (Global memory, upper 32 bits)
  write_register(32'h02c, scalar_p_ptr[63:32]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 3: result_p (0x034) -> Randomized 4k aligned address (Global memory, lower 32 bits)
  write_register(32'h034, result_p_ptr[31:0]);

  ///////////////////////////////////////////////////////////////////////////
  //Write ID 3: result_p (0x038) -> Randomized 4k aligned address (Global memory, upper 32 bits)
  write_register(32'h038, result_p_ptr[63:32]);

endtask

task automatic backdoor_fill_memories();

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Backdoor fill the memory with the content.
  point_fill_memory(point_p_ptr, LP_MAX_LENGTH);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Backdoor fill the memory with the content.
  scalar_fill_memory(scalar_p_ptr, LP_MAX_LENGTH);

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Backdoor fill the memory with the content.
  result_fill_memory(result_p_ptr, LP_MAX_LENGTH);

endtask

function automatic bit check_kernel_result();
  bit [31:0]        ret_rd_value = 32'h0;
  bit error_found = 0;
  integer error_counter;
  error_counter = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to point
  for (longint unsigned slot = 0; slot < LP_MAX_LENGTH; slot++) begin
    ret_rd_value = point.mem_model.backdoor_memory_read_4byte(point_p_ptr + (slot * 4));
    if (slot < LP_MAX_TRANSFER_LENGTH) begin
      if (ret_rd_value != (slot + 1)) begin
        $error("Memory Mismatch: point : @0x%x : Expected 0x%x -> Got 0x%x ", point_p_ptr + (slot * 4), slot + 1, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end else begin
      if (ret_rd_value != slot) begin
        $error("Memory Mismatch: point : @0x%x : Expected 0x%x -> Got 0x%x ", point_p_ptr + (slot * 4), slot, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end
    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of point.");
      slot = LP_MAX_LENGTH;
    end
  end
  error_counter = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to scalar
  for (longint unsigned slot = 0; slot < LP_MAX_LENGTH; slot++) begin
    ret_rd_value = scalar.mem_model.backdoor_memory_read_4byte(scalar_p_ptr + (slot * 4));
    if (slot < LP_MAX_TRANSFER_LENGTH) begin
      if (ret_rd_value != (slot + 1)) begin
        $error("Memory Mismatch: scalar : @0x%x : Expected 0x%x -> Got 0x%x ", scalar_p_ptr + (slot * 4), slot + 1, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end else begin
      if (ret_rd_value != slot) begin
        $error("Memory Mismatch: scalar : @0x%x : Expected 0x%x -> Got 0x%x ", scalar_p_ptr + (slot * 4), slot, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end
    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of scalar.");
      slot = LP_MAX_LENGTH;
    end
  end
  error_counter = 0;

  /////////////////////////////////////////////////////////////////////////////////////////////////
  // Checking memory connected to result
  for (longint unsigned slot = 0; slot < LP_MAX_LENGTH; slot++) begin
    ret_rd_value = result.mem_model.backdoor_memory_read_4byte(result_p_ptr + (slot * 4));
    if (slot < LP_MAX_TRANSFER_LENGTH) begin
      if (ret_rd_value != (slot + 1)) begin
        $error("Memory Mismatch: result : @0x%x : Expected 0x%x -> Got 0x%x ", result_p_ptr + (slot * 4), slot + 1, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end else begin
      if (ret_rd_value != slot) begin
        $error("Memory Mismatch: result : @0x%x : Expected 0x%x -> Got 0x%x ", result_p_ptr + (slot * 4), slot, ret_rd_value);
        error_found |= 1;
        error_counter++;
      end
    end
    if (error_counter > 5) begin
      $display("Too many errors found. Exiting check of result.");
      slot = LP_MAX_LENGTH;
    end
  end
  error_counter = 0;

  return(error_found);
endfunction

bit choose_pressure_type = 0;
bit axis_choose_pressure_type = 0;
bit [0-1:0] axis_tlast_received;

/////////////////////////////////////////////////////////////////////////////////////////////////
// Set up the kernel for operation and set the kernel START bit.
// The task will poll the DONE bit and check the results when complete.
task automatic multiple_iteration(input integer unsigned num_iterations, output bit error_found);
  error_found = 0;

  $display("Starting: multiple_iteration");
  for (integer unsigned iter = 0; iter < num_iterations; iter++) begin

    
    $display("Starting iteration: %d / %d", iter+1, num_iterations);
    RAND_WREADY_PRESSURE_FAILED: assert(std::randomize(choose_pressure_type));
    case(choose_pressure_type)
      0: slv_no_backpressure_wready();
      1: slv_random_backpressure_wready();
    endcase
    RAND_RVALID_PRESSURE_FAILED: assert(std::randomize(choose_pressure_type));
    case(choose_pressure_type)
      0: slv_no_delay_rvalid();
      1: slv_random_delay_rvalid();
    endcase

    set_scalar_registers();
    set_memory_pointers();
    backdoor_fill_memories();
    // Check that Kernel is IDLE before starting.
    poll_idle_register();
    ///////////////////////////////////////////////////////////////////////////
    //Start transfers
    blocking_write_register(KRNL_CTRL_REG_ADDR, CTRL_START_MASK);

    ctrl.wait_drivers_idle();
    ///////////////////////////////////////////////////////////////////////////
    //Wait for interrupt being asserted or poll done register
    @(posedge interrupt);

    ///////////////////////////////////////////////////////////////////////////
    // Service the interrupt
    service_interrupts();
    wait(interrupt == 0);

    ///////////////////////////////////////////////////////////////////////////
    error_found |= check_kernel_result()   ;

    $display("Finished iteration: %d / %d", iter+1, num_iterations);
  end
 endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
//Instantiate AXI4 LITE VIP
initial begin : STIMULUS
  #200000;
  start_vips();
  check_scalar_registers(error_found);
  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end

  check_pointer_registers(error_found);
  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end

  enable_interrupts();

  multiple_iteration(1, error_found);
  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end

  multiple_iteration(5, error_found);

  if (error_found == 1) begin
    $display( "Test Failed!");
    $finish();
  end else begin
    $display( "Test completed successfully");
  end
  $finish;
end

endmodule
`default_nettype wire

