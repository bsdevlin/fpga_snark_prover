// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
#ifndef XMULTIEXP_KERNEL_H
#define XMULTIEXP_KERNEL_H

#ifdef __cplusplus
extern "C" {
#endif

/***************************** Include Files *********************************/
#ifndef __linux__
#include "xil_types.h"
#include "xil_assert.h"
#include "xstatus.h"
#include "xil_io.h"
#else
#include <stdint.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stddef.h>
#endif
#include "xmultiexp_kernel_hw.h"

/**************************** Type Definitions ******************************/
#ifdef __linux__
typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
#else
typedef struct {
    u16 DeviceId;
    u32 Control_BaseAddress;
} XMultiexp_kernel_Config;
#endif

typedef struct {
    u32 Control_BaseAddress;
    u32 IsReady;
} XMultiexp_kernel;

/***************** Macros (Inline Functions) Definitions *********************/
#ifndef __linux__
#define XMultiexp_kernel_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))
#define XMultiexp_kernel_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))
#else
#define XMultiexp_kernel_WriteReg(BaseAddress, RegOffset, Data) \
    *(volatile u32*)((BaseAddress) + (RegOffset)) = (u32)(Data)
#define XMultiexp_kernel_ReadReg(BaseAddress, RegOffset) \
    *(volatile u32*)((BaseAddress) + (RegOffset))

#define Xil_AssertVoid(expr)    assert(expr)
#define Xil_AssertNonvoid(expr) assert(expr)

#define XST_SUCCESS             0
#define XST_DEVICE_NOT_FOUND    2
#define XST_OPEN_DEVICE_FAILED  3
#define XIL_COMPONENT_IS_READY  1
#endif

/************************** Function Prototypes *****************************/
#ifndef __linux__
int XMultiexp_kernel_Initialize(XMultiexp_kernel *InstancePtr, u16 DeviceId);
XMultiexp_kernel_Config* XMultiexp_kernel_LookupConfig(u16 DeviceId);
int XMultiexp_kernel_CfgInitialize(XMultiexp_kernel *InstancePtr, XMultiexp_kernel_Config *ConfigPtr);
#else
int XMultiexp_kernel_Initialize(XMultiexp_kernel *InstancePtr, const char* InstanceName);
int XMultiexp_kernel_Release(XMultiexp_kernel *InstancePtr);
#endif

void XMultiexp_kernel_Start(XMultiexp_kernel *InstancePtr);
u32 XMultiexp_kernel_IsDone(XMultiexp_kernel *InstancePtr);
u32 XMultiexp_kernel_IsIdle(XMultiexp_kernel *InstancePtr);
u32 XMultiexp_kernel_IsReady(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_EnableAutoRestart(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_DisableAutoRestart(XMultiexp_kernel *InstancePtr);

void XMultiexp_kernel_Set_num_in(XMultiexp_kernel *InstancePtr, u64 Data);
u64 XMultiexp_kernel_Get_num_in(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_Set_point_p(XMultiexp_kernel *InstancePtr, u64 Data);
u64 XMultiexp_kernel_Get_point_p(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_Set_scalar_p(XMultiexp_kernel *InstancePtr, u64 Data);
u64 XMultiexp_kernel_Get_scalar_p(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_Set_result_p(XMultiexp_kernel *InstancePtr, u64 Data);
u64 XMultiexp_kernel_Get_result_p(XMultiexp_kernel *InstancePtr);

void XMultiexp_kernel_InterruptGlobalEnable(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_InterruptGlobalDisable(XMultiexp_kernel *InstancePtr);
void XMultiexp_kernel_InterruptEnable(XMultiexp_kernel *InstancePtr, u32 Mask);
void XMultiexp_kernel_InterruptDisable(XMultiexp_kernel *InstancePtr, u32 Mask);
void XMultiexp_kernel_InterruptClear(XMultiexp_kernel *InstancePtr, u32 Mask);
u32 XMultiexp_kernel_InterruptGetEnabled(XMultiexp_kernel *InstancePtr);
u32 XMultiexp_kernel_InterruptGetStatus(XMultiexp_kernel *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
