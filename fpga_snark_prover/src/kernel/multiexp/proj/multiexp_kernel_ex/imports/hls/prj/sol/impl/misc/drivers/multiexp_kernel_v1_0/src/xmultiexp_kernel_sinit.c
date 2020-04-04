// ==============================================================
// Vivado(TM) HLS - High-Level Synthesis from C, C++ and SystemC v2019.2 (64-bit)
// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// ==============================================================
#ifndef __linux__

#include "xstatus.h"
#include "xparameters.h"
#include "xmultiexp_kernel.h"

extern XMultiexp_kernel_Config XMultiexp_kernel_ConfigTable[];

XMultiexp_kernel_Config *XMultiexp_kernel_LookupConfig(u16 DeviceId) {
	XMultiexp_kernel_Config *ConfigPtr = NULL;

	int Index;

	for (Index = 0; Index < XPAR_XMULTIEXP_KERNEL_NUM_INSTANCES; Index++) {
		if (XMultiexp_kernel_ConfigTable[Index].DeviceId == DeviceId) {
			ConfigPtr = &XMultiexp_kernel_ConfigTable[Index];
			break;
		}
	}

	return ConfigPtr;
}

int XMultiexp_kernel_Initialize(XMultiexp_kernel *InstancePtr, u16 DeviceId) {
	XMultiexp_kernel_Config *ConfigPtr;

	Xil_AssertNonvoid(InstancePtr != NULL);

	ConfigPtr = XMultiexp_kernel_LookupConfig(DeviceId);
	if (ConfigPtr == NULL) {
		InstancePtr->IsReady = 0;
		return (XST_DEVICE_NOT_FOUND);
	}

	return XMultiexp_kernel_CfgInitialize(InstancePtr, ConfigPtr);
}

#endif

