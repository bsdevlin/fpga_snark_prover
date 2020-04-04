set moduleName multiexp_kernel
set isTopModule 1
set isTaskLevelControl 1
set isCombinational 0
set isDatapathOnly 0
set isFreeRunPipelineModule 0
set isPipelined 0
set pipeline_type none
set FunctionProtocol ap_ctrl_hs
set isOneStateSeq 0
set ProfileFlag 0
set StallSigGenFlag 0
set isEnableWaveformDebug 1
set C_modelName {multiexp_kernel}
set C_modelType { void 0 }
set C_modelArgList {
	{ point int 32 regular {axi_master 2}  }
	{ scalar int 32 regular {axi_master 2}  }
	{ result int 32 regular {axi_master 2}  }
	{ num_in double 64 unused {axi_slave 0}  }
	{ point_p int 64 regular {axi_slave 0}  }
	{ scalar_p int 64 regular {axi_slave 0}  }
	{ result_p int 64 regular {axi_slave 0}  }
}
set C_modelArgMapList {[ 
	{ "Name" : "point", "interface" : "axi_master", "bitwidth" : 32, "direction" : "READWRITE", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "point_p","cData": "int","bit_use": { "low": 0,"up": 31},"offset": { "type": "dynamic","port_name": "point_p","bundle": "control"},"direction": "READWRITE","cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]}]} , 
 	{ "Name" : "scalar", "interface" : "axi_master", "bitwidth" : 32, "direction" : "READWRITE", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "scalar_p","cData": "int","bit_use": { "low": 0,"up": 31},"offset": { "type": "dynamic","port_name": "scalar_p","bundle": "control"},"direction": "READWRITE","cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]}]} , 
 	{ "Name" : "result", "interface" : "axi_master", "bitwidth" : 32, "direction" : "READWRITE", "bitSlice":[{"low":0,"up":31,"cElement": [{"cName": "result_p","cData": "int","bit_use": { "low": 0,"up": 31},"offset": { "type": "dynamic","port_name": "result_p","bundle": "control"},"direction": "READWRITE","cArray": [{"low" : 0,"up" : 0,"step" : 1}]}]}]} , 
 	{ "Name" : "num_in", "interface" : "axi_slave", "bundle":"control","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "bitSlice":[{"low":0,"up":63,"cElement": [{"cName": "num_in","cData": "double","bit_use": { "low": 0,"up": 63},"cArray": [{"low" : 0,"up" : 0,"step" : 0}]}]}], "offset" : {"in":16}, "offset_end" : {"in":27}} , 
 	{ "Name" : "point_p", "interface" : "axi_slave", "bundle":"control","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "offset" : {"in":28}, "offset_end" : {"in":39}} , 
 	{ "Name" : "scalar_p", "interface" : "axi_slave", "bundle":"control","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "offset" : {"in":40}, "offset_end" : {"in":51}} , 
 	{ "Name" : "result_p", "interface" : "axi_slave", "bundle":"control","type":"ap_none","bitwidth" : 64, "direction" : "READONLY", "offset" : {"in":52}, "offset_end" : {"in":63}} ]}
# RTL Port declarations: 
set portNum 155
set portList { 
	{ ap_clk sc_in sc_logic 1 clock -1 } 
	{ ap_rst_n sc_in sc_logic 1 reset -1 active_low_sync } 
	{ m_axi_point_AWVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_AWREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_AWADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_point_AWID sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_AWLEN sc_out sc_lv 8 signal 0 } 
	{ m_axi_point_AWSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_point_AWBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_point_AWLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_point_AWCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_AWPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_point_AWQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_AWREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_AWUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_WVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_WREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_WDATA sc_out sc_lv 32 signal 0 } 
	{ m_axi_point_WSTRB sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_WLAST sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_WID sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_WUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_ARVALID sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_ARREADY sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_ARADDR sc_out sc_lv 64 signal 0 } 
	{ m_axi_point_ARID sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_ARLEN sc_out sc_lv 8 signal 0 } 
	{ m_axi_point_ARSIZE sc_out sc_lv 3 signal 0 } 
	{ m_axi_point_ARBURST sc_out sc_lv 2 signal 0 } 
	{ m_axi_point_ARLOCK sc_out sc_lv 2 signal 0 } 
	{ m_axi_point_ARCACHE sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_ARPROT sc_out sc_lv 3 signal 0 } 
	{ m_axi_point_ARQOS sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_ARREGION sc_out sc_lv 4 signal 0 } 
	{ m_axi_point_ARUSER sc_out sc_lv 1 signal 0 } 
	{ m_axi_point_RVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_RREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_RDATA sc_in sc_lv 32 signal 0 } 
	{ m_axi_point_RLAST sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_RID sc_in sc_lv 1 signal 0 } 
	{ m_axi_point_RUSER sc_in sc_lv 1 signal 0 } 
	{ m_axi_point_RRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_point_BVALID sc_in sc_logic 1 signal 0 } 
	{ m_axi_point_BREADY sc_out sc_logic 1 signal 0 } 
	{ m_axi_point_BRESP sc_in sc_lv 2 signal 0 } 
	{ m_axi_point_BID sc_in sc_lv 1 signal 0 } 
	{ m_axi_point_BUSER sc_in sc_lv 1 signal 0 } 
	{ m_axi_scalar_AWVALID sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_AWREADY sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_AWADDR sc_out sc_lv 64 signal 1 } 
	{ m_axi_scalar_AWID sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_AWLEN sc_out sc_lv 8 signal 1 } 
	{ m_axi_scalar_AWSIZE sc_out sc_lv 3 signal 1 } 
	{ m_axi_scalar_AWBURST sc_out sc_lv 2 signal 1 } 
	{ m_axi_scalar_AWLOCK sc_out sc_lv 2 signal 1 } 
	{ m_axi_scalar_AWCACHE sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_AWPROT sc_out sc_lv 3 signal 1 } 
	{ m_axi_scalar_AWQOS sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_AWREGION sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_AWUSER sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_WVALID sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_WREADY sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_WDATA sc_out sc_lv 32 signal 1 } 
	{ m_axi_scalar_WSTRB sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_WLAST sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_WID sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_WUSER sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_ARVALID sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_ARREADY sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_ARADDR sc_out sc_lv 64 signal 1 } 
	{ m_axi_scalar_ARID sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_ARLEN sc_out sc_lv 8 signal 1 } 
	{ m_axi_scalar_ARSIZE sc_out sc_lv 3 signal 1 } 
	{ m_axi_scalar_ARBURST sc_out sc_lv 2 signal 1 } 
	{ m_axi_scalar_ARLOCK sc_out sc_lv 2 signal 1 } 
	{ m_axi_scalar_ARCACHE sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_ARPROT sc_out sc_lv 3 signal 1 } 
	{ m_axi_scalar_ARQOS sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_ARREGION sc_out sc_lv 4 signal 1 } 
	{ m_axi_scalar_ARUSER sc_out sc_lv 1 signal 1 } 
	{ m_axi_scalar_RVALID sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_RREADY sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_RDATA sc_in sc_lv 32 signal 1 } 
	{ m_axi_scalar_RLAST sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_RID sc_in sc_lv 1 signal 1 } 
	{ m_axi_scalar_RUSER sc_in sc_lv 1 signal 1 } 
	{ m_axi_scalar_RRESP sc_in sc_lv 2 signal 1 } 
	{ m_axi_scalar_BVALID sc_in sc_logic 1 signal 1 } 
	{ m_axi_scalar_BREADY sc_out sc_logic 1 signal 1 } 
	{ m_axi_scalar_BRESP sc_in sc_lv 2 signal 1 } 
	{ m_axi_scalar_BID sc_in sc_lv 1 signal 1 } 
	{ m_axi_scalar_BUSER sc_in sc_lv 1 signal 1 } 
	{ m_axi_result_AWVALID sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_AWREADY sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_AWADDR sc_out sc_lv 64 signal 2 } 
	{ m_axi_result_AWID sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_AWLEN sc_out sc_lv 8 signal 2 } 
	{ m_axi_result_AWSIZE sc_out sc_lv 3 signal 2 } 
	{ m_axi_result_AWBURST sc_out sc_lv 2 signal 2 } 
	{ m_axi_result_AWLOCK sc_out sc_lv 2 signal 2 } 
	{ m_axi_result_AWCACHE sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_AWPROT sc_out sc_lv 3 signal 2 } 
	{ m_axi_result_AWQOS sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_AWREGION sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_AWUSER sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_WVALID sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_WREADY sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_WDATA sc_out sc_lv 32 signal 2 } 
	{ m_axi_result_WSTRB sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_WLAST sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_WID sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_WUSER sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_ARVALID sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_ARREADY sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_ARADDR sc_out sc_lv 64 signal 2 } 
	{ m_axi_result_ARID sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_ARLEN sc_out sc_lv 8 signal 2 } 
	{ m_axi_result_ARSIZE sc_out sc_lv 3 signal 2 } 
	{ m_axi_result_ARBURST sc_out sc_lv 2 signal 2 } 
	{ m_axi_result_ARLOCK sc_out sc_lv 2 signal 2 } 
	{ m_axi_result_ARCACHE sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_ARPROT sc_out sc_lv 3 signal 2 } 
	{ m_axi_result_ARQOS sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_ARREGION sc_out sc_lv 4 signal 2 } 
	{ m_axi_result_ARUSER sc_out sc_lv 1 signal 2 } 
	{ m_axi_result_RVALID sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_RREADY sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_RDATA sc_in sc_lv 32 signal 2 } 
	{ m_axi_result_RLAST sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_RID sc_in sc_lv 1 signal 2 } 
	{ m_axi_result_RUSER sc_in sc_lv 1 signal 2 } 
	{ m_axi_result_RRESP sc_in sc_lv 2 signal 2 } 
	{ m_axi_result_BVALID sc_in sc_logic 1 signal 2 } 
	{ m_axi_result_BREADY sc_out sc_logic 1 signal 2 } 
	{ m_axi_result_BRESP sc_in sc_lv 2 signal 2 } 
	{ m_axi_result_BID sc_in sc_lv 1 signal 2 } 
	{ m_axi_result_BUSER sc_in sc_lv 1 signal 2 } 
	{ s_axi_control_AWVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_control_AWREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_control_AWADDR sc_in sc_lv 6 signal -1 } 
	{ s_axi_control_WVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_control_WREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_control_WDATA sc_in sc_lv 32 signal -1 } 
	{ s_axi_control_WSTRB sc_in sc_lv 4 signal -1 } 
	{ s_axi_control_ARVALID sc_in sc_logic 1 signal -1 } 
	{ s_axi_control_ARREADY sc_out sc_logic 1 signal -1 } 
	{ s_axi_control_ARADDR sc_in sc_lv 6 signal -1 } 
	{ s_axi_control_RVALID sc_out sc_logic 1 signal -1 } 
	{ s_axi_control_RREADY sc_in sc_logic 1 signal -1 } 
	{ s_axi_control_RDATA sc_out sc_lv 32 signal -1 } 
	{ s_axi_control_RRESP sc_out sc_lv 2 signal -1 } 
	{ s_axi_control_BVALID sc_out sc_logic 1 signal -1 } 
	{ s_axi_control_BREADY sc_in sc_logic 1 signal -1 } 
	{ s_axi_control_BRESP sc_out sc_lv 2 signal -1 } 
	{ interrupt sc_out sc_logic 1 signal -1 } 
}
set NewPortList {[ 
	{ "name": "s_axi_control_AWADDR", "direction": "in", "datatype": "sc_lv", "bitwidth":6, "type": "signal", "bundle":{"name": "control", "role": "AWADDR" },"address":[{"name":"multiexp_kernel","role":"start","value":"0","valid_bit":"0"},{"name":"multiexp_kernel","role":"continue","value":"0","valid_bit":"4"},{"name":"multiexp_kernel","role":"auto_start","value":"0","valid_bit":"7"},{"name":"num_in","role":"data","value":"16"},{"name":"point_p","role":"data","value":"28"},{"name":"scalar_p","role":"data","value":"40"},{"name":"result_p","role":"data","value":"52"}] },
	{ "name": "s_axi_control_AWVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "AWVALID" } },
	{ "name": "s_axi_control_AWREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "AWREADY" } },
	{ "name": "s_axi_control_WVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "WVALID" } },
	{ "name": "s_axi_control_WREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "WREADY" } },
	{ "name": "s_axi_control_WDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "control", "role": "WDATA" } },
	{ "name": "s_axi_control_WSTRB", "direction": "in", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "control", "role": "WSTRB" } },
	{ "name": "s_axi_control_ARADDR", "direction": "in", "datatype": "sc_lv", "bitwidth":6, "type": "signal", "bundle":{"name": "control", "role": "ARADDR" },"address":[{"name":"multiexp_kernel","role":"start","value":"0","valid_bit":"0"},{"name":"multiexp_kernel","role":"done","value":"0","valid_bit":"1"},{"name":"multiexp_kernel","role":"idle","value":"0","valid_bit":"2"},{"name":"multiexp_kernel","role":"ready","value":"0","valid_bit":"3"},{"name":"multiexp_kernel","role":"auto_start","value":"0","valid_bit":"7"}] },
	{ "name": "s_axi_control_ARVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "ARVALID" } },
	{ "name": "s_axi_control_ARREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "ARREADY" } },
	{ "name": "s_axi_control_RVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "RVALID" } },
	{ "name": "s_axi_control_RREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "RREADY" } },
	{ "name": "s_axi_control_RDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "control", "role": "RDATA" } },
	{ "name": "s_axi_control_RRESP", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "control", "role": "RRESP" } },
	{ "name": "s_axi_control_BVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "BVALID" } },
	{ "name": "s_axi_control_BREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "BREADY" } },
	{ "name": "s_axi_control_BRESP", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "control", "role": "BRESP" } },
	{ "name": "interrupt", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "control", "role": "interrupt" } }, 
 	{ "name": "ap_clk", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "clock", "bundle":{"name": "ap_clk", "role": "default" }} , 
 	{ "name": "ap_rst_n", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "reset", "bundle":{"name": "ap_rst_n", "role": "default" }} , 
 	{ "name": "m_axi_point_AWVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "AWVALID" }} , 
 	{ "name": "m_axi_point_AWREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "AWREADY" }} , 
 	{ "name": "m_axi_point_AWADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "point", "role": "AWADDR" }} , 
 	{ "name": "m_axi_point_AWID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "AWID" }} , 
 	{ "name": "m_axi_point_AWLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "point", "role": "AWLEN" }} , 
 	{ "name": "m_axi_point_AWSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "point", "role": "AWSIZE" }} , 
 	{ "name": "m_axi_point_AWBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "AWBURST" }} , 
 	{ "name": "m_axi_point_AWLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "AWLOCK" }} , 
 	{ "name": "m_axi_point_AWCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "AWCACHE" }} , 
 	{ "name": "m_axi_point_AWPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "point", "role": "AWPROT" }} , 
 	{ "name": "m_axi_point_AWQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "AWQOS" }} , 
 	{ "name": "m_axi_point_AWREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "AWREGION" }} , 
 	{ "name": "m_axi_point_AWUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "AWUSER" }} , 
 	{ "name": "m_axi_point_WVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "WVALID" }} , 
 	{ "name": "m_axi_point_WREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "WREADY" }} , 
 	{ "name": "m_axi_point_WDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "point", "role": "WDATA" }} , 
 	{ "name": "m_axi_point_WSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "WSTRB" }} , 
 	{ "name": "m_axi_point_WLAST", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "WLAST" }} , 
 	{ "name": "m_axi_point_WID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "WID" }} , 
 	{ "name": "m_axi_point_WUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "WUSER" }} , 
 	{ "name": "m_axi_point_ARVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "ARVALID" }} , 
 	{ "name": "m_axi_point_ARREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "ARREADY" }} , 
 	{ "name": "m_axi_point_ARADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "point", "role": "ARADDR" }} , 
 	{ "name": "m_axi_point_ARID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "ARID" }} , 
 	{ "name": "m_axi_point_ARLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "point", "role": "ARLEN" }} , 
 	{ "name": "m_axi_point_ARSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "point", "role": "ARSIZE" }} , 
 	{ "name": "m_axi_point_ARBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "ARBURST" }} , 
 	{ "name": "m_axi_point_ARLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "ARLOCK" }} , 
 	{ "name": "m_axi_point_ARCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "ARCACHE" }} , 
 	{ "name": "m_axi_point_ARPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "point", "role": "ARPROT" }} , 
 	{ "name": "m_axi_point_ARQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "ARQOS" }} , 
 	{ "name": "m_axi_point_ARREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "point", "role": "ARREGION" }} , 
 	{ "name": "m_axi_point_ARUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "ARUSER" }} , 
 	{ "name": "m_axi_point_RVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "RVALID" }} , 
 	{ "name": "m_axi_point_RREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "RREADY" }} , 
 	{ "name": "m_axi_point_RDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "point", "role": "RDATA" }} , 
 	{ "name": "m_axi_point_RLAST", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "RLAST" }} , 
 	{ "name": "m_axi_point_RID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "RID" }} , 
 	{ "name": "m_axi_point_RUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "RUSER" }} , 
 	{ "name": "m_axi_point_RRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "RRESP" }} , 
 	{ "name": "m_axi_point_BVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "BVALID" }} , 
 	{ "name": "m_axi_point_BREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "BREADY" }} , 
 	{ "name": "m_axi_point_BRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "point", "role": "BRESP" }} , 
 	{ "name": "m_axi_point_BID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "BID" }} , 
 	{ "name": "m_axi_point_BUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "point", "role": "BUSER" }} , 
 	{ "name": "m_axi_scalar_AWVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "AWVALID" }} , 
 	{ "name": "m_axi_scalar_AWREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "AWREADY" }} , 
 	{ "name": "m_axi_scalar_AWADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "scalar", "role": "AWADDR" }} , 
 	{ "name": "m_axi_scalar_AWID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "AWID" }} , 
 	{ "name": "m_axi_scalar_AWLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "scalar", "role": "AWLEN" }} , 
 	{ "name": "m_axi_scalar_AWSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "scalar", "role": "AWSIZE" }} , 
 	{ "name": "m_axi_scalar_AWBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "AWBURST" }} , 
 	{ "name": "m_axi_scalar_AWLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "AWLOCK" }} , 
 	{ "name": "m_axi_scalar_AWCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "AWCACHE" }} , 
 	{ "name": "m_axi_scalar_AWPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "scalar", "role": "AWPROT" }} , 
 	{ "name": "m_axi_scalar_AWQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "AWQOS" }} , 
 	{ "name": "m_axi_scalar_AWREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "AWREGION" }} , 
 	{ "name": "m_axi_scalar_AWUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "AWUSER" }} , 
 	{ "name": "m_axi_scalar_WVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "WVALID" }} , 
 	{ "name": "m_axi_scalar_WREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "WREADY" }} , 
 	{ "name": "m_axi_scalar_WDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "scalar", "role": "WDATA" }} , 
 	{ "name": "m_axi_scalar_WSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "WSTRB" }} , 
 	{ "name": "m_axi_scalar_WLAST", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "WLAST" }} , 
 	{ "name": "m_axi_scalar_WID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "WID" }} , 
 	{ "name": "m_axi_scalar_WUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "WUSER" }} , 
 	{ "name": "m_axi_scalar_ARVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "ARVALID" }} , 
 	{ "name": "m_axi_scalar_ARREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "ARREADY" }} , 
 	{ "name": "m_axi_scalar_ARADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "scalar", "role": "ARADDR" }} , 
 	{ "name": "m_axi_scalar_ARID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "ARID" }} , 
 	{ "name": "m_axi_scalar_ARLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "scalar", "role": "ARLEN" }} , 
 	{ "name": "m_axi_scalar_ARSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "scalar", "role": "ARSIZE" }} , 
 	{ "name": "m_axi_scalar_ARBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "ARBURST" }} , 
 	{ "name": "m_axi_scalar_ARLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "ARLOCK" }} , 
 	{ "name": "m_axi_scalar_ARCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "ARCACHE" }} , 
 	{ "name": "m_axi_scalar_ARPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "scalar", "role": "ARPROT" }} , 
 	{ "name": "m_axi_scalar_ARQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "ARQOS" }} , 
 	{ "name": "m_axi_scalar_ARREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "scalar", "role": "ARREGION" }} , 
 	{ "name": "m_axi_scalar_ARUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "ARUSER" }} , 
 	{ "name": "m_axi_scalar_RVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "RVALID" }} , 
 	{ "name": "m_axi_scalar_RREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "RREADY" }} , 
 	{ "name": "m_axi_scalar_RDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "scalar", "role": "RDATA" }} , 
 	{ "name": "m_axi_scalar_RLAST", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "RLAST" }} , 
 	{ "name": "m_axi_scalar_RID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "RID" }} , 
 	{ "name": "m_axi_scalar_RUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "RUSER" }} , 
 	{ "name": "m_axi_scalar_RRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "RRESP" }} , 
 	{ "name": "m_axi_scalar_BVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "BVALID" }} , 
 	{ "name": "m_axi_scalar_BREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "BREADY" }} , 
 	{ "name": "m_axi_scalar_BRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "scalar", "role": "BRESP" }} , 
 	{ "name": "m_axi_scalar_BID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "BID" }} , 
 	{ "name": "m_axi_scalar_BUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "scalar", "role": "BUSER" }} , 
 	{ "name": "m_axi_result_AWVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "AWVALID" }} , 
 	{ "name": "m_axi_result_AWREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "AWREADY" }} , 
 	{ "name": "m_axi_result_AWADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "result", "role": "AWADDR" }} , 
 	{ "name": "m_axi_result_AWID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "AWID" }} , 
 	{ "name": "m_axi_result_AWLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "result", "role": "AWLEN" }} , 
 	{ "name": "m_axi_result_AWSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "result", "role": "AWSIZE" }} , 
 	{ "name": "m_axi_result_AWBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "AWBURST" }} , 
 	{ "name": "m_axi_result_AWLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "AWLOCK" }} , 
 	{ "name": "m_axi_result_AWCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "AWCACHE" }} , 
 	{ "name": "m_axi_result_AWPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "result", "role": "AWPROT" }} , 
 	{ "name": "m_axi_result_AWQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "AWQOS" }} , 
 	{ "name": "m_axi_result_AWREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "AWREGION" }} , 
 	{ "name": "m_axi_result_AWUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "AWUSER" }} , 
 	{ "name": "m_axi_result_WVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "WVALID" }} , 
 	{ "name": "m_axi_result_WREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "WREADY" }} , 
 	{ "name": "m_axi_result_WDATA", "direction": "out", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "result", "role": "WDATA" }} , 
 	{ "name": "m_axi_result_WSTRB", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "WSTRB" }} , 
 	{ "name": "m_axi_result_WLAST", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "WLAST" }} , 
 	{ "name": "m_axi_result_WID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "WID" }} , 
 	{ "name": "m_axi_result_WUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "WUSER" }} , 
 	{ "name": "m_axi_result_ARVALID", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "ARVALID" }} , 
 	{ "name": "m_axi_result_ARREADY", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "ARREADY" }} , 
 	{ "name": "m_axi_result_ARADDR", "direction": "out", "datatype": "sc_lv", "bitwidth":64, "type": "signal", "bundle":{"name": "result", "role": "ARADDR" }} , 
 	{ "name": "m_axi_result_ARID", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "ARID" }} , 
 	{ "name": "m_axi_result_ARLEN", "direction": "out", "datatype": "sc_lv", "bitwidth":8, "type": "signal", "bundle":{"name": "result", "role": "ARLEN" }} , 
 	{ "name": "m_axi_result_ARSIZE", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "result", "role": "ARSIZE" }} , 
 	{ "name": "m_axi_result_ARBURST", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "ARBURST" }} , 
 	{ "name": "m_axi_result_ARLOCK", "direction": "out", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "ARLOCK" }} , 
 	{ "name": "m_axi_result_ARCACHE", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "ARCACHE" }} , 
 	{ "name": "m_axi_result_ARPROT", "direction": "out", "datatype": "sc_lv", "bitwidth":3, "type": "signal", "bundle":{"name": "result", "role": "ARPROT" }} , 
 	{ "name": "m_axi_result_ARQOS", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "ARQOS" }} , 
 	{ "name": "m_axi_result_ARREGION", "direction": "out", "datatype": "sc_lv", "bitwidth":4, "type": "signal", "bundle":{"name": "result", "role": "ARREGION" }} , 
 	{ "name": "m_axi_result_ARUSER", "direction": "out", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "ARUSER" }} , 
 	{ "name": "m_axi_result_RVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "RVALID" }} , 
 	{ "name": "m_axi_result_RREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "RREADY" }} , 
 	{ "name": "m_axi_result_RDATA", "direction": "in", "datatype": "sc_lv", "bitwidth":32, "type": "signal", "bundle":{"name": "result", "role": "RDATA" }} , 
 	{ "name": "m_axi_result_RLAST", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "RLAST" }} , 
 	{ "name": "m_axi_result_RID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "RID" }} , 
 	{ "name": "m_axi_result_RUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "RUSER" }} , 
 	{ "name": "m_axi_result_RRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "RRESP" }} , 
 	{ "name": "m_axi_result_BVALID", "direction": "in", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "BVALID" }} , 
 	{ "name": "m_axi_result_BREADY", "direction": "out", "datatype": "sc_logic", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "BREADY" }} , 
 	{ "name": "m_axi_result_BRESP", "direction": "in", "datatype": "sc_lv", "bitwidth":2, "type": "signal", "bundle":{"name": "result", "role": "BRESP" }} , 
 	{ "name": "m_axi_result_BID", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "BID" }} , 
 	{ "name": "m_axi_result_BUSER", "direction": "in", "datatype": "sc_lv", "bitwidth":1, "type": "signal", "bundle":{"name": "result", "role": "BUSER" }}  ]}

set RtlHierarchyInfo {[
	{"ID" : "0", "Level" : "0", "Path" : "`AUTOTB_DUT_INST", "Parent" : "", "Child" : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
		"CDFG" : "multiexp_kernel",
		"Protocol" : "ap_ctrl_hs",
		"ControlExist" : "1", "ap_start" : "1", "ap_ready" : "1", "ap_done" : "1", "ap_continue" : "0", "ap_idle" : "1",
		"Pipeline" : "None", "UnalignedPipeline" : "0", "RewindPipeline" : "0", "ProcessNetwork" : "0",
		"II" : "0",
		"VariableLatency" : "1", "ExactLatency" : "-1", "EstimateLatencyMin" : "36911", "EstimateLatencyMax" : "36911",
		"Combinational" : "0",
		"Datapath" : "0",
		"ClockEnable" : "0",
		"HasSubDataflow" : "0",
		"InDataflowNetwork" : "0",
		"HasNonBlockingOperation" : "0",
		"Port" : [
			{"Name" : "point", "Type" : "MAXI", "Direction" : "IO",
				"BlockSignal" : [
					{"Name" : "point_blk_n_AR", "Type" : "RtlSignal"},
					{"Name" : "point_blk_n_R", "Type" : "RtlSignal"},
					{"Name" : "point_blk_n_AW", "Type" : "RtlSignal"},
					{"Name" : "point_blk_n_B", "Type" : "RtlSignal"},
					{"Name" : "point_blk_n_W", "Type" : "RtlSignal"}]},
			{"Name" : "scalar", "Type" : "MAXI", "Direction" : "IO",
				"BlockSignal" : [
					{"Name" : "scalar_blk_n_AR", "Type" : "RtlSignal"},
					{"Name" : "scalar_blk_n_R", "Type" : "RtlSignal"},
					{"Name" : "scalar_blk_n_AW", "Type" : "RtlSignal"},
					{"Name" : "scalar_blk_n_B", "Type" : "RtlSignal"},
					{"Name" : "scalar_blk_n_W", "Type" : "RtlSignal"}]},
			{"Name" : "result", "Type" : "MAXI", "Direction" : "IO",
				"BlockSignal" : [
					{"Name" : "result_blk_n_AR", "Type" : "RtlSignal"},
					{"Name" : "result_blk_n_R", "Type" : "RtlSignal"},
					{"Name" : "result_blk_n_AW", "Type" : "RtlSignal"},
					{"Name" : "result_blk_n_W", "Type" : "RtlSignal"},
					{"Name" : "result_blk_n_B", "Type" : "RtlSignal"}]},
			{"Name" : "num_in", "Type" : "None", "Direction" : "I"},
			{"Name" : "point_p", "Type" : "None", "Direction" : "I"},
			{"Name" : "scalar_p", "Type" : "None", "Direction" : "I"},
			{"Name" : "result_p", "Type" : "None", "Direction" : "I"}]},
	{"ID" : "1", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.multiexp_kernel_control_s_axi_U", "Parent" : "0"},
	{"ID" : "2", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.multiexp_kernel_point_m_axi_U", "Parent" : "0"},
	{"ID" : "3", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.multiexp_kernel_scalar_m_axi_U", "Parent" : "0"},
	{"ID" : "4", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.multiexp_kernel_result_m_axi_U", "Parent" : "0"},
	{"ID" : "5", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.point_input_buffer_U", "Parent" : "0"},
	{"ID" : "6", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.point_output_buffer_U", "Parent" : "0"},
	{"ID" : "7", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.scalar_input_buffer_U", "Parent" : "0"},
	{"ID" : "8", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.scalar_output_buffer_U", "Parent" : "0"},
	{"ID" : "9", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.result_input_buffer_U", "Parent" : "0"},
	{"ID" : "10", "Level" : "1", "Path" : "`AUTOTB_DUT_INST.result_output_buffer_U", "Parent" : "0"}]}


set ArgLastReadFirstWriteLatency {
	multiexp_kernel {
		point {Type IO LastRead 14 FirstWrite 14}
		scalar {Type IO LastRead 26 FirstWrite 26}
		result {Type IO LastRead 37 FirstWrite 38}
		num_in {Type I LastRead -1 FirstWrite -1}
		point_p {Type I LastRead 0 FirstWrite -1}
		scalar_p {Type I LastRead 0 FirstWrite -1}
		result_p {Type I LastRead 0 FirstWrite -1}}}

set hasDtUnsupportedChannel 0

set PerformanceInfo {[
	{"Name" : "Latency", "Min" : "36911", "Max" : "36911"}
	, {"Name" : "Interval", "Min" : "36912", "Max" : "36912"}
]}

set PipelineEnableSignalInfo {[
	{"Pipeline" : "0", "EnableSignal" : "ap_enable_pp0"}
	{"Pipeline" : "1", "EnableSignal" : "ap_enable_pp1"}
	{"Pipeline" : "2", "EnableSignal" : "ap_enable_pp2"}
	{"Pipeline" : "3", "EnableSignal" : "ap_enable_pp3"}
	{"Pipeline" : "4", "EnableSignal" : "ap_enable_pp4"}
	{"Pipeline" : "5", "EnableSignal" : "ap_enable_pp5"}
	{"Pipeline" : "6", "EnableSignal" : "ap_enable_pp6"}
	{"Pipeline" : "7", "EnableSignal" : "ap_enable_pp7"}
	{"Pipeline" : "8", "EnableSignal" : "ap_enable_pp8"}
]}

set Spec2ImplPortList { 
	point { m_axi {  { m_axi_point_AWVALID VALID 1 1 }  { m_axi_point_AWREADY READY 0 1 }  { m_axi_point_AWADDR ADDR 1 64 }  { m_axi_point_AWID ID 1 1 }  { m_axi_point_AWLEN LEN 1 8 }  { m_axi_point_AWSIZE SIZE 1 3 }  { m_axi_point_AWBURST BURST 1 2 }  { m_axi_point_AWLOCK LOCK 1 2 }  { m_axi_point_AWCACHE CACHE 1 4 }  { m_axi_point_AWPROT PROT 1 3 }  { m_axi_point_AWQOS QOS 1 4 }  { m_axi_point_AWREGION REGION 1 4 }  { m_axi_point_AWUSER USER 1 1 }  { m_axi_point_WVALID VALID 1 1 }  { m_axi_point_WREADY READY 0 1 }  { m_axi_point_WDATA DATA 1 32 }  { m_axi_point_WSTRB STRB 1 4 }  { m_axi_point_WLAST LAST 1 1 }  { m_axi_point_WID ID 1 1 }  { m_axi_point_WUSER USER 1 1 }  { m_axi_point_ARVALID VALID 1 1 }  { m_axi_point_ARREADY READY 0 1 }  { m_axi_point_ARADDR ADDR 1 64 }  { m_axi_point_ARID ID 1 1 }  { m_axi_point_ARLEN LEN 1 8 }  { m_axi_point_ARSIZE SIZE 1 3 }  { m_axi_point_ARBURST BURST 1 2 }  { m_axi_point_ARLOCK LOCK 1 2 }  { m_axi_point_ARCACHE CACHE 1 4 }  { m_axi_point_ARPROT PROT 1 3 }  { m_axi_point_ARQOS QOS 1 4 }  { m_axi_point_ARREGION REGION 1 4 }  { m_axi_point_ARUSER USER 1 1 }  { m_axi_point_RVALID VALID 0 1 }  { m_axi_point_RREADY READY 1 1 }  { m_axi_point_RDATA DATA 0 32 }  { m_axi_point_RLAST LAST 0 1 }  { m_axi_point_RID ID 0 1 }  { m_axi_point_RUSER USER 0 1 }  { m_axi_point_RRESP RESP 0 2 }  { m_axi_point_BVALID VALID 0 1 }  { m_axi_point_BREADY READY 1 1 }  { m_axi_point_BRESP RESP 0 2 }  { m_axi_point_BID ID 0 1 }  { m_axi_point_BUSER USER 0 1 } } }
	scalar { m_axi {  { m_axi_scalar_AWVALID VALID 1 1 }  { m_axi_scalar_AWREADY READY 0 1 }  { m_axi_scalar_AWADDR ADDR 1 64 }  { m_axi_scalar_AWID ID 1 1 }  { m_axi_scalar_AWLEN LEN 1 8 }  { m_axi_scalar_AWSIZE SIZE 1 3 }  { m_axi_scalar_AWBURST BURST 1 2 }  { m_axi_scalar_AWLOCK LOCK 1 2 }  { m_axi_scalar_AWCACHE CACHE 1 4 }  { m_axi_scalar_AWPROT PROT 1 3 }  { m_axi_scalar_AWQOS QOS 1 4 }  { m_axi_scalar_AWREGION REGION 1 4 }  { m_axi_scalar_AWUSER USER 1 1 }  { m_axi_scalar_WVALID VALID 1 1 }  { m_axi_scalar_WREADY READY 0 1 }  { m_axi_scalar_WDATA DATA 1 32 }  { m_axi_scalar_WSTRB STRB 1 4 }  { m_axi_scalar_WLAST LAST 1 1 }  { m_axi_scalar_WID ID 1 1 }  { m_axi_scalar_WUSER USER 1 1 }  { m_axi_scalar_ARVALID VALID 1 1 }  { m_axi_scalar_ARREADY READY 0 1 }  { m_axi_scalar_ARADDR ADDR 1 64 }  { m_axi_scalar_ARID ID 1 1 }  { m_axi_scalar_ARLEN LEN 1 8 }  { m_axi_scalar_ARSIZE SIZE 1 3 }  { m_axi_scalar_ARBURST BURST 1 2 }  { m_axi_scalar_ARLOCK LOCK 1 2 }  { m_axi_scalar_ARCACHE CACHE 1 4 }  { m_axi_scalar_ARPROT PROT 1 3 }  { m_axi_scalar_ARQOS QOS 1 4 }  { m_axi_scalar_ARREGION REGION 1 4 }  { m_axi_scalar_ARUSER USER 1 1 }  { m_axi_scalar_RVALID VALID 0 1 }  { m_axi_scalar_RREADY READY 1 1 }  { m_axi_scalar_RDATA DATA 0 32 }  { m_axi_scalar_RLAST LAST 0 1 }  { m_axi_scalar_RID ID 0 1 }  { m_axi_scalar_RUSER USER 0 1 }  { m_axi_scalar_RRESP RESP 0 2 }  { m_axi_scalar_BVALID VALID 0 1 }  { m_axi_scalar_BREADY READY 1 1 }  { m_axi_scalar_BRESP RESP 0 2 }  { m_axi_scalar_BID ID 0 1 }  { m_axi_scalar_BUSER USER 0 1 } } }
	result { m_axi {  { m_axi_result_AWVALID VALID 1 1 }  { m_axi_result_AWREADY READY 0 1 }  { m_axi_result_AWADDR ADDR 1 64 }  { m_axi_result_AWID ID 1 1 }  { m_axi_result_AWLEN LEN 1 8 }  { m_axi_result_AWSIZE SIZE 1 3 }  { m_axi_result_AWBURST BURST 1 2 }  { m_axi_result_AWLOCK LOCK 1 2 }  { m_axi_result_AWCACHE CACHE 1 4 }  { m_axi_result_AWPROT PROT 1 3 }  { m_axi_result_AWQOS QOS 1 4 }  { m_axi_result_AWREGION REGION 1 4 }  { m_axi_result_AWUSER USER 1 1 }  { m_axi_result_WVALID VALID 1 1 }  { m_axi_result_WREADY READY 0 1 }  { m_axi_result_WDATA DATA 1 32 }  { m_axi_result_WSTRB STRB 1 4 }  { m_axi_result_WLAST LAST 1 1 }  { m_axi_result_WID ID 1 1 }  { m_axi_result_WUSER USER 1 1 }  { m_axi_result_ARVALID VALID 1 1 }  { m_axi_result_ARREADY READY 0 1 }  { m_axi_result_ARADDR ADDR 1 64 }  { m_axi_result_ARID ID 1 1 }  { m_axi_result_ARLEN LEN 1 8 }  { m_axi_result_ARSIZE SIZE 1 3 }  { m_axi_result_ARBURST BURST 1 2 }  { m_axi_result_ARLOCK LOCK 1 2 }  { m_axi_result_ARCACHE CACHE 1 4 }  { m_axi_result_ARPROT PROT 1 3 }  { m_axi_result_ARQOS QOS 1 4 }  { m_axi_result_ARREGION REGION 1 4 }  { m_axi_result_ARUSER USER 1 1 }  { m_axi_result_RVALID VALID 0 1 }  { m_axi_result_RREADY READY 1 1 }  { m_axi_result_RDATA DATA 0 32 }  { m_axi_result_RLAST LAST 0 1 }  { m_axi_result_RID ID 0 1 }  { m_axi_result_RUSER USER 0 1 }  { m_axi_result_RRESP RESP 0 2 }  { m_axi_result_BVALID VALID 0 1 }  { m_axi_result_BREADY READY 1 1 }  { m_axi_result_BRESP RESP 0 2 }  { m_axi_result_BID ID 0 1 }  { m_axi_result_BUSER USER 0 1 } } }
}

set busDeadlockParameterList { 
	{ point { NUM_READ_OUTSTANDING 16 NUM_WRITE_OUTSTANDING 16 MAX_READ_BURST_LENGTH 16 MAX_WRITE_BURST_LENGTH 16 } } \
	{ scalar { NUM_READ_OUTSTANDING 16 NUM_WRITE_OUTSTANDING 16 MAX_READ_BURST_LENGTH 16 MAX_WRITE_BURST_LENGTH 16 } } \
	{ result { NUM_READ_OUTSTANDING 16 NUM_WRITE_OUTSTANDING 16 MAX_READ_BURST_LENGTH 16 MAX_WRITE_BURST_LENGTH 16 } } \
}

# RTL port scheduling information:
set fifoSchedulingInfoList { 
}

# RTL bus port read request latency information:
set busReadReqLatencyList { 
	{ point 1 }
	{ scalar 1 }
	{ result 1 }
}

# RTL bus port write response latency information:
set busWriteResLatencyList { 
	{ point 1 }
	{ scalar 1 }
	{ result 1 }
}

# RTL array port load latency information:
set memoryLoadLatencyList { 
}
