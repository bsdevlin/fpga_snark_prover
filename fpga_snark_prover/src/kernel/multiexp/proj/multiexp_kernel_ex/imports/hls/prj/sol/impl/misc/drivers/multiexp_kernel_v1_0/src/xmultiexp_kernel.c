// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
/***************************** Include Files *********************************/
#include "xmultiexp_kernel.h"

/************************** Function Implementation *************************/
#ifndef __linux__
int XMultiexp_kernel_CfgInitialize(XMultiexp_kernel *InstancePtr, XMultiexp_kernel_Config *ConfigPtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(ConfigPtr != NULL);

    InstancePtr->Control_BaseAddress = ConfigPtr->Control_BaseAddress;
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}
#endif

void XMultiexp_kernel_Start(XMultiexp_kernel *InstancePtr) {
    u32 Data;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL) & 0x80;
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL, Data | 0x01);
}

u32 XMultiexp_kernel_IsDone(XMultiexp_kernel *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL);
    return (Data >> 1) & 0x1;
}

u32 XMultiexp_kernel_IsIdle(XMultiexp_kernel *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL);
    return (Data >> 2) & 0x1;
}

u32 XMultiexp_kernel_IsReady(XMultiexp_kernel *InstancePtr) {
    u32 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL);
    // check ap_start to see if the pcore is ready for next input
    return !(Data & 0x1);
}

void XMultiexp_kernel_EnableAutoRestart(XMultiexp_kernel *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL, 0x80);
}

void XMultiexp_kernel_DisableAutoRestart(XMultiexp_kernel *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_AP_CTRL, 0);
}

void XMultiexp_kernel_Set_num_in(XMultiexp_kernel *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_NUM_IN_DATA, (u32)(Data));
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_NUM_IN_DATA + 4, (u32)(Data >> 32));
}

u64 XMultiexp_kernel_Get_num_in(XMultiexp_kernel *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_NUM_IN_DATA);
    Data += (u64)XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_NUM_IN_DATA + 4) << 32;
    return Data;
}

void XMultiexp_kernel_Set_point_p(XMultiexp_kernel *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_POINT_P_DATA, (u32)(Data));
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_POINT_P_DATA + 4, (u32)(Data >> 32));
}

u64 XMultiexp_kernel_Get_point_p(XMultiexp_kernel *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_POINT_P_DATA);
    Data += (u64)XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_POINT_P_DATA + 4) << 32;
    return Data;
}

void XMultiexp_kernel_Set_scalar_p(XMultiexp_kernel *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_SCALAR_P_DATA, (u32)(Data));
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_SCALAR_P_DATA + 4, (u32)(Data >> 32));
}

u64 XMultiexp_kernel_Get_scalar_p(XMultiexp_kernel *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_SCALAR_P_DATA);
    Data += (u64)XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_SCALAR_P_DATA + 4) << 32;
    return Data;
}

void XMultiexp_kernel_Set_result_p(XMultiexp_kernel *InstancePtr, u64 Data) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_RESULT_P_DATA, (u32)(Data));
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_RESULT_P_DATA + 4, (u32)(Data >> 32));
}

u64 XMultiexp_kernel_Get_result_p(XMultiexp_kernel *InstancePtr) {
    u64 Data;

    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Data = XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_RESULT_P_DATA);
    Data += (u64)XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_RESULT_P_DATA + 4) << 32;
    return Data;
}

void XMultiexp_kernel_InterruptGlobalEnable(XMultiexp_kernel *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_GIE, 1);
}

void XMultiexp_kernel_InterruptGlobalDisable(XMultiexp_kernel *InstancePtr) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_GIE, 0);
}

void XMultiexp_kernel_InterruptEnable(XMultiexp_kernel *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_IER);
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_IER, Register | Mask);
}

void XMultiexp_kernel_InterruptDisable(XMultiexp_kernel *InstancePtr, u32 Mask) {
    u32 Register;

    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    Register =  XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_IER);
    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_IER, Register & (~Mask));
}

void XMultiexp_kernel_InterruptClear(XMultiexp_kernel *InstancePtr, u32 Mask) {
    Xil_AssertVoid(InstancePtr != NULL);
    Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    XMultiexp_kernel_WriteReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_ISR, Mask);
}

u32 XMultiexp_kernel_InterruptGetEnabled(XMultiexp_kernel *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_IER);
}

u32 XMultiexp_kernel_InterruptGetStatus(XMultiexp_kernel *InstancePtr) {
    Xil_AssertNonvoid(InstancePtr != NULL);
    Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

    return XMultiexp_kernel_ReadReg(InstancePtr->Control_BaseAddress, XMULTIEXP_KERNEL_CONTROL_ADDR_ISR);
}

