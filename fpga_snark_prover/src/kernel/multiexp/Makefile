.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make all TARGET=<hw_emu/hw>"
	$(ECHO) "      Command to generate the design for specified Target and Shell."
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""
	$(ECHO) "  make check TARGET=<hw_emu/hw>"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) "      By default, HOST_ARCH=x86. HOST_ARCH and SYSROOT is required for SoC shells"
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<hw_emu/hw>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) ""

KERNEL_NAME := multiexp_kernel
EXECUTABLE := host
BUILD_DIR := build_output
DEVICE := $(AWS_PLATFORM)
TARGET := hw
HOST_ARCH := x86

# Points to top directory of Git Vitis repository
COMMON_REPO = ../../../../submodules/aws-fpga/Vitis/examples/xilinx/
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

include $(ABS_COMMON_REPO)/common/includes/opencl/opencl.mk
include $(ABS_COMMON_REPO)/common/includes/xcl2/xcl2.mk
CXX := $(XILINX_VIVADO)/tps/lnx64/gcc-6.2.0/bin/g++
CXXFLAGS += $(xcl2_CXXFLAGS) -I/opt/xilinx/xrt/include
CXXFLAGS += -Wall -O0 -g -std=c++11
LDFLAGS += -L/opt/xilinx/xrt/lib -lOpenCL -lpthread  -lrt -lstdc++ -lgmp
VPP := v++
HOST_SRCS += $(xcl2_SRCS)
HOST_SRCS += src/host.cpp ../shared/bn128.cpp
HOST_INC := -I../shared/
BINARY_CONTAINERS += $(BUILD_DIR)/$(KERNEL_NAME).xclbin
BINARY_CONTAINER_vadd_OBJS += bin/$(KERNEL_NAME).xo

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps 
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif

#CLFLAGS += --sp multiexp_kernel_1.point_p:DDR[0:3] --sp multiexp_kernel_1.result_p:DDR[0:3] --sp multiexp_kernel_1.scalar_p:DDR[0:3]


ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif


.PHONY: all clean cleanall $(BUILD_DIR)
exe: $(EXECUTABLE)

.PHONY: build
build: $(BINARY_CONTAINERS)

# Building kernel
$(BUILD_DIR)/$(KERNEL_NAME).xclbin: $(BINARY_CONTAINER_vadd_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) -o'$@' $(+)

# Building Host
$(EXECUTABLE): $(HOST_SRCS)
	mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(HOST_INC) $(HOST_SRCS) -o '$(BUILD_DIR)/$@' $(LDFLAGS)
	
