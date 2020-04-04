// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
// control
// 0x00 : Control signals
//        bit 0  - ap_start (Read/Write/COH)
//        bit 1  - ap_done (Read/COR)
//        bit 2  - ap_idle (Read)
//        bit 3  - ap_ready (Read)
//        bit 7  - auto_restart (Read/Write)
//        others - reserved
// 0x04 : Global Interrupt Enable Register
//        bit 0  - Global Interrupt Enable (Read/Write)
//        others - reserved
// 0x08 : IP Interrupt Enable Register (Read/Write)
//        bit 0  - Channel 0 (ap_done)
//        bit 1  - Channel 1 (ap_ready)
//        others - reserved
// 0x0c : IP Interrupt Status Register (Read/TOW)
//        bit 0  - Channel 0 (ap_done)
//        bit 1  - Channel 1 (ap_ready)
//        others - reserved
// 0x10 : Data signal of num_in
//        bit 31~0 - num_in[31:0] (Read/Write)
// 0x14 : Data signal of num_in
//        bit 31~0 - num_in[63:32] (Read/Write)
// 0x18 : reserved
// 0x1c : Data signal of point_p
//        bit 31~0 - point_p[31:0] (Read/Write)
// 0x20 : Data signal of point_p
//        bit 31~0 - point_p[63:32] (Read/Write)
// 0x24 : reserved
// 0x28 : Data signal of scalar_p
//        bit 31~0 - scalar_p[31:0] (Read/Write)
// 0x2c : Data signal of scalar_p
//        bit 31~0 - scalar_p[63:32] (Read/Write)
// 0x30 : reserved
// 0x34 : Data signal of result_p
//        bit 31~0 - result_p[31:0] (Read/Write)
// 0x38 : Data signal of result_p
//        bit 31~0 - result_p[63:32] (Read/Write)
// 0x3c : reserved
// (SC = Self Clear, COR = Clear on Read, TOW = Toggle on Write, COH = Clear on Handshake)

#define XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL       0x00
#define XMULTIEXP_KERNEL_CONTROL_ADDR_GIE           0x04
#define XMULTIEXP_KERNEL_CONTROL_ADDR_IER           0x08
#define XMULTIEXP_KERNEL_CONTROL_ADDR_ISR           0x0c
#define XMULTIEXP_KERNEL_CONTROL_ADDR_NUM_IN_DATA   0x10
#define XMULTIEXP_KERNEL_CONTROL_BITS_NUM_IN_DATA   64
#define XMULTIEXP_KERNEL_CONTROL_ADDR_POINT_P_DATA  0x1c
#define XMULTIEXP_KERNEL_CONTROL_BITS_POINT_P_DATA  64
#define XMULTIEXP_KERNEL_CONTROL_ADDR_SCALAR_P_DATA 0x28
#define XMULTIEXP_KERNEL_CONTROL_BITS_SCALAR_P_DATA 64
#define XMULTIEXP_KERNEL_CONTROL_ADDR_RESULT_P_DATA 0x34
#define XMULTIEXP_KERNEL_CONTROL_BITS_RESULT_P_DATA 64

