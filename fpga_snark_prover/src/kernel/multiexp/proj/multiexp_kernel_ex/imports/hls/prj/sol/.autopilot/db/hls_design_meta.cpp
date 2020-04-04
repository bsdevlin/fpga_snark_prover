#include "hls_design_meta.h"
const Port_Property HLS_Design_Meta::port_props[]={
	Port_Property("ap_clk", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_rst_n", 1, hls_in, -1, "", "", 1),
	Port_Property("m_axi_point_AWVALID", 1, hls_out, 0, "m_axi", "VALID", 1),
	Port_Property("m_axi_point_AWREADY", 1, hls_in, 0, "m_axi", "READY", 1),
	Port_Property("m_axi_point_AWADDR", 64, hls_out, 0, "m_axi", "ADDR", 1),
	Port_Property("m_axi_point_AWID", 1, hls_out, 0, "m_axi", "ID", 1),
	Port_Property("m_axi_point_AWLEN", 8, hls_out, 0, "m_axi", "LEN", 1),
	Port_Property("m_axi_point_AWSIZE", 3, hls_out, 0, "m_axi", "SIZE", 1),
	Port_Property("m_axi_point_AWBURST", 2, hls_out, 0, "m_axi", "BURST", 1),
	Port_Property("m_axi_point_AWLOCK", 2, hls_out, 0, "m_axi", "LOCK", 1),
	Port_Property("m_axi_point_AWCACHE", 4, hls_out, 0, "m_axi", "CACHE", 1),
	Port_Property("m_axi_point_AWPROT", 3, hls_out, 0, "m_axi", "PROT", 1),
	Port_Property("m_axi_point_AWQOS", 4, hls_out, 0, "m_axi", "QOS", 1),
	Port_Property("m_axi_point_AWREGION", 4, hls_out, 0, "m_axi", "REGION", 1),
	Port_Property("m_axi_point_AWUSER", 1, hls_out, 0, "m_axi", "USER", 1),
	Port_Property("m_axi_point_WVALID", 1, hls_out, 0, "m_axi", "VALID", 1),
	Port_Property("m_axi_point_WREADY", 1, hls_in, 0, "m_axi", "READY", 1),
	Port_Property("m_axi_point_WDATA", 32, hls_out, 0, "m_axi", "DATA", 1),
	Port_Property("m_axi_point_WSTRB", 4, hls_out, 0, "m_axi", "STRB", 1),
	Port_Property("m_axi_point_WLAST", 1, hls_out, 0, "m_axi", "LAST", 1),
	Port_Property("m_axi_point_WID", 1, hls_out, 0, "m_axi", "ID", 1),
	Port_Property("m_axi_point_WUSER", 1, hls_out, 0, "m_axi", "USER", 1),
	Port_Property("m_axi_point_ARVALID", 1, hls_out, 0, "m_axi", "VALID", 1),
	Port_Property("m_axi_point_ARREADY", 1, hls_in, 0, "m_axi", "READY", 1),
	Port_Property("m_axi_point_ARADDR", 64, hls_out, 0, "m_axi", "ADDR", 1),
	Port_Property("m_axi_point_ARID", 1, hls_out, 0, "m_axi", "ID", 1),
	Port_Property("m_axi_point_ARLEN", 8, hls_out, 0, "m_axi", "LEN", 1),
	Port_Property("m_axi_point_ARSIZE", 3, hls_out, 0, "m_axi", "SIZE", 1),
	Port_Property("m_axi_point_ARBURST", 2, hls_out, 0, "m_axi", "BURST", 1),
	Port_Property("m_axi_point_ARLOCK", 2, hls_out, 0, "m_axi", "LOCK", 1),
	Port_Property("m_axi_point_ARCACHE", 4, hls_out, 0, "m_axi", "CACHE", 1),
	Port_Property("m_axi_point_ARPROT", 3, hls_out, 0, "m_axi", "PROT", 1),
	Port_Property("m_axi_point_ARQOS", 4, hls_out, 0, "m_axi", "QOS", 1),
	Port_Property("m_axi_point_ARREGION", 4, hls_out, 0, "m_axi", "REGION", 1),
	Port_Property("m_axi_point_ARUSER", 1, hls_out, 0, "m_axi", "USER", 1),
	Port_Property("m_axi_point_RVALID", 1, hls_in, 0, "m_axi", "VALID", 1),
	Port_Property("m_axi_point_RREADY", 1, hls_out, 0, "m_axi", "READY", 1),
	Port_Property("m_axi_point_RDATA", 32, hls_in, 0, "m_axi", "DATA", 1),
	Port_Property("m_axi_point_RLAST", 1, hls_in, 0, "m_axi", "LAST", 1),
	Port_Property("m_axi_point_RID", 1, hls_in, 0, "m_axi", "ID", 1),
	Port_Property("m_axi_point_RUSER", 1, hls_in, 0, "m_axi", "USER", 1),
	Port_Property("m_axi_point_RRESP", 2, hls_in, 0, "m_axi", "RESP", 1),
	Port_Property("m_axi_point_BVALID", 1, hls_in, 0, "m_axi", "VALID", 1),
	Port_Property("m_axi_point_BREADY", 1, hls_out, 0, "m_axi", "READY", 1),
	Port_Property("m_axi_point_BRESP", 2, hls_in, 0, "m_axi", "RESP", 1),
	Port_Property("m_axi_point_BID", 1, hls_in, 0, "m_axi", "ID", 1),
	Port_Property("m_axi_point_BUSER", 1, hls_in, 0, "m_axi", "USER", 1),
	Port_Property("m_axi_scalar_AWVALID", 1, hls_out, 1, "m_axi", "VALID", 1),
	Port_Property("m_axi_scalar_AWREADY", 1, hls_in, 1, "m_axi", "READY", 1),
	Port_Property("m_axi_scalar_AWADDR", 64, hls_out, 1, "m_axi", "ADDR", 1),
	Port_Property("m_axi_scalar_AWID", 1, hls_out, 1, "m_axi", "ID", 1),
	Port_Property("m_axi_scalar_AWLEN", 8, hls_out, 1, "m_axi", "LEN", 1),
	Port_Property("m_axi_scalar_AWSIZE", 3, hls_out, 1, "m_axi", "SIZE", 1),
	Port_Property("m_axi_scalar_AWBURST", 2, hls_out, 1, "m_axi", "BURST", 1),
	Port_Property("m_axi_scalar_AWLOCK", 2, hls_out, 1, "m_axi", "LOCK", 1),
	Port_Property("m_axi_scalar_AWCACHE", 4, hls_out, 1, "m_axi", "CACHE", 1),
	Port_Property("m_axi_scalar_AWPROT", 3, hls_out, 1, "m_axi", "PROT", 1),
	Port_Property("m_axi_scalar_AWQOS", 4, hls_out, 1, "m_axi", "QOS", 1),
	Port_Property("m_axi_scalar_AWREGION", 4, hls_out, 1, "m_axi", "REGION", 1),
	Port_Property("m_axi_scalar_AWUSER", 1, hls_out, 1, "m_axi", "USER", 1),
	Port_Property("m_axi_scalar_WVALID", 1, hls_out, 1, "m_axi", "VALID", 1),
	Port_Property("m_axi_scalar_WREADY", 1, hls_in, 1, "m_axi", "READY", 1),
	Port_Property("m_axi_scalar_WDATA", 32, hls_out, 1, "m_axi", "DATA", 1),
	Port_Property("m_axi_scalar_WSTRB", 4, hls_out, 1, "m_axi", "STRB", 1),
	Port_Property("m_axi_scalar_WLAST", 1, hls_out, 1, "m_axi", "LAST", 1),
	Port_Property("m_axi_scalar_WID", 1, hls_out, 1, "m_axi", "ID", 1),
	Port_Property("m_axi_scalar_WUSER", 1, hls_out, 1, "m_axi", "USER", 1),
	Port_Property("m_axi_scalar_ARVALID", 1, hls_out, 1, "m_axi", "VALID", 1),
	Port_Property("m_axi_scalar_ARREADY", 1, hls_in, 1, "m_axi", "READY", 1),
	Port_Property("m_axi_scalar_ARADDR", 64, hls_out, 1, "m_axi", "ADDR", 1),
	Port_Property("m_axi_scalar_ARID", 1, hls_out, 1, "m_axi", "ID", 1),
	Port_Property("m_axi_scalar_ARLEN", 8, hls_out, 1, "m_axi", "LEN", 1),
	Port_Property("m_axi_scalar_ARSIZE", 3, hls_out, 1, "m_axi", "SIZE", 1),
	Port_Property("m_axi_scalar_ARBURST", 2, hls_out, 1, "m_axi", "BURST", 1),
	Port_Property("m_axi_scalar_ARLOCK", 2, hls_out, 1, "m_axi", "LOCK", 1),
	Port_Property("m_axi_scalar_ARCACHE", 4, hls_out, 1, "m_axi", "CACHE", 1),
	Port_Property("m_axi_scalar_ARPROT", 3, hls_out, 1, "m_axi", "PROT", 1),
	Port_Property("m_axi_scalar_ARQOS", 4, hls_out, 1, "m_axi", "QOS", 1),
	Port_Property("m_axi_scalar_ARREGION", 4, hls_out, 1, "m_axi", "REGION", 1),
	Port_Property("m_axi_scalar_ARUSER", 1, hls_out, 1, "m_axi", "USER", 1),
	Port_Property("m_axi_scalar_RVALID", 1, hls_in, 1, "m_axi", "VALID", 1),
	Port_Property("m_axi_scalar_RREADY", 1, hls_out, 1, "m_axi", "READY", 1),
	Port_Property("m_axi_scalar_RDATA", 32, hls_in, 1, "m_axi", "DATA", 1),
	Port_Property("m_axi_scalar_RLAST", 1, hls_in, 1, "m_axi", "LAST", 1),
	Port_Property("m_axi_scalar_RID", 1, hls_in, 1, "m_axi", "ID", 1),
	Port_Property("m_axi_scalar_RUSER", 1, hls_in, 1, "m_axi", "USER", 1),
	Port_Property("m_axi_scalar_RRESP", 2, hls_in, 1, "m_axi", "RESP", 1),
	Port_Property("m_axi_scalar_BVALID", 1, hls_in, 1, "m_axi", "VALID", 1),
	Port_Property("m_axi_scalar_BREADY", 1, hls_out, 1, "m_axi", "READY", 1),
	Port_Property("m_axi_scalar_BRESP", 2, hls_in, 1, "m_axi", "RESP", 1),
	Port_Property("m_axi_scalar_BID", 1, hls_in, 1, "m_axi", "ID", 1),
	Port_Property("m_axi_scalar_BUSER", 1, hls_in, 1, "m_axi", "USER", 1),
	Port_Property("m_axi_result_AWVALID", 1, hls_out, 2, "m_axi", "VALID", 1),
	Port_Property("m_axi_result_AWREADY", 1, hls_in, 2, "m_axi", "READY", 1),
	Port_Property("m_axi_result_AWADDR", 64, hls_out, 2, "m_axi", "ADDR", 1),
	Port_Property("m_axi_result_AWID", 1, hls_out, 2, "m_axi", "ID", 1),
	Port_Property("m_axi_result_AWLEN", 8, hls_out, 2, "m_axi", "LEN", 1),
	Port_Property("m_axi_result_AWSIZE", 3, hls_out, 2, "m_axi", "SIZE", 1),
	Port_Property("m_axi_result_AWBURST", 2, hls_out, 2, "m_axi", "BURST", 1),
	Port_Property("m_axi_result_AWLOCK", 2, hls_out, 2, "m_axi", "LOCK", 1),
	Port_Property("m_axi_result_AWCACHE", 4, hls_out, 2, "m_axi", "CACHE", 1),
	Port_Property("m_axi_result_AWPROT", 3, hls_out, 2, "m_axi", "PROT", 1),
	Port_Property("m_axi_result_AWQOS", 4, hls_out, 2, "m_axi", "QOS", 1),
	Port_Property("m_axi_result_AWREGION", 4, hls_out, 2, "m_axi", "REGION", 1),
	Port_Property("m_axi_result_AWUSER", 1, hls_out, 2, "m_axi", "USER", 1),
	Port_Property("m_axi_result_WVALID", 1, hls_out, 2, "m_axi", "VALID", 1),
	Port_Property("m_axi_result_WREADY", 1, hls_in, 2, "m_axi", "READY", 1),
	Port_Property("m_axi_result_WDATA", 32, hls_out, 2, "m_axi", "DATA", 1),
	Port_Property("m_axi_result_WSTRB", 4, hls_out, 2, "m_axi", "STRB", 1),
	Port_Property("m_axi_result_WLAST", 1, hls_out, 2, "m_axi", "LAST", 1),
	Port_Property("m_axi_result_WID", 1, hls_out, 2, "m_axi", "ID", 1),
	Port_Property("m_axi_result_WUSER", 1, hls_out, 2, "m_axi", "USER", 1),
	Port_Property("m_axi_result_ARVALID", 1, hls_out, 2, "m_axi", "VALID", 1),
	Port_Property("m_axi_result_ARREADY", 1, hls_in, 2, "m_axi", "READY", 1),
	Port_Property("m_axi_result_ARADDR", 64, hls_out, 2, "m_axi", "ADDR", 1),
	Port_Property("m_axi_result_ARID", 1, hls_out, 2, "m_axi", "ID", 1),
	Port_Property("m_axi_result_ARLEN", 8, hls_out, 2, "m_axi", "LEN", 1),
	Port_Property("m_axi_result_ARSIZE", 3, hls_out, 2, "m_axi", "SIZE", 1),
	Port_Property("m_axi_result_ARBURST", 2, hls_out, 2, "m_axi", "BURST", 1),
	Port_Property("m_axi_result_ARLOCK", 2, hls_out, 2, "m_axi", "LOCK", 1),
	Port_Property("m_axi_result_ARCACHE", 4, hls_out, 2, "m_axi", "CACHE", 1),
	Port_Property("m_axi_result_ARPROT", 3, hls_out, 2, "m_axi", "PROT", 1),
	Port_Property("m_axi_result_ARQOS", 4, hls_out, 2, "m_axi", "QOS", 1),
	Port_Property("m_axi_result_ARREGION", 4, hls_out, 2, "m_axi", "REGION", 1),
	Port_Property("m_axi_result_ARUSER", 1, hls_out, 2, "m_axi", "USER", 1),
	Port_Property("m_axi_result_RVALID", 1, hls_in, 2, "m_axi", "VALID", 1),
	Port_Property("m_axi_result_RREADY", 1, hls_out, 2, "m_axi", "READY", 1),
	Port_Property("m_axi_result_RDATA", 32, hls_in, 2, "m_axi", "DATA", 1),
	Port_Property("m_axi_result_RLAST", 1, hls_in, 2, "m_axi", "LAST", 1),
	Port_Property("m_axi_result_RID", 1, hls_in, 2, "m_axi", "ID", 1),
	Port_Property("m_axi_result_RUSER", 1, hls_in, 2, "m_axi", "USER", 1),
	Port_Property("m_axi_result_RRESP", 2, hls_in, 2, "m_axi", "RESP", 1),
	Port_Property("m_axi_result_BVALID", 1, hls_in, 2, "m_axi", "VALID", 1),
	Port_Property("m_axi_result_BREADY", 1, hls_out, 2, "m_axi", "READY", 1),
	Port_Property("m_axi_result_BRESP", 2, hls_in, 2, "m_axi", "RESP", 1),
	Port_Property("m_axi_result_BID", 1, hls_in, 2, "m_axi", "ID", 1),
	Port_Property("m_axi_result_BUSER", 1, hls_in, 2, "m_axi", "USER", 1),
	Port_Property("s_axi_control_AWVALID", 1, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_AWREADY", 1, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_AWADDR", 6, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_WVALID", 1, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_WREADY", 1, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_WDATA", 32, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_WSTRB", 4, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_ARVALID", 1, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_ARREADY", 1, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_ARADDR", 6, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_RVALID", 1, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_RREADY", 1, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_RDATA", 32, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_RRESP", 2, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_BVALID", 1, hls_out, -1, "", "", 1),
	Port_Property("s_axi_control_BREADY", 1, hls_in, -1, "", "", 1),
	Port_Property("s_axi_control_BRESP", 2, hls_out, -1, "", "", 1),
	Port_Property("interrupt", 1, hls_out, -1, "", "", 1),
};
const char* HLS_Design_Meta::dut_name = "multiexp_kernel";
