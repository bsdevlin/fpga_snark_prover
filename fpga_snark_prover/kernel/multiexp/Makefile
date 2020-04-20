.PHONY: help

help::
	$(ECHO) "Makefile Usage, default TARGET is emulation (hw_emu)."
	$(ECHO) "  make all TARGET=<hw_emu/hw>"
	$(ECHO) "      Command to generate the design for specified Target and Shell and run the test program."
	$(ECHO) ""
	$(ECHO) "  make to_f1 S3_BUCKET=<S3 name of your bucket>"
	$(ECHO) "      Command to create the AFI and .awsxclbin required to run on the AWS FPGA. You need to have a S3 bucket to upload files to"
	$(ECHO) ""
	$(ECHO) "  make clean "
	$(ECHO) "      Command to remove the generated non-hardware files."
	$(ECHO) ""
	$(ECHO) "  make cleanall"
	$(ECHO) "      Command to remove all the generated files."
	$(ECHO) ""

KERNEL_NAME := multiexp_kernel
BUILD_DIR := build_output
EXECUTABLE := $(BUILD_DIR)/host.exe
DEVICE := $(AWS_PLATFORM)
TARGET := hw_emu
HOST_ARCH := x86
F1_FILE := $(BUILD_DIR)/to_f1.tar.gz
S3_BUCKET := your_bucket_name

# Points to top directory of Git Vitis repository
COMMON_REPO = $(AWS_FPGA_REPO_DIR)/Vitis/examples/xilinx/
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
KERNEL_XCL = $(BUILD_DIR)/$(KERNEL_NAME)_$(TARGET).xclbin  
BINARY_CONTAINER_vadd_OBJS += bin/$(KERNEL_NAME).xo
BINARY_CONTAINER_AWS = $(KERNEL_NAME)_hw.awsxclbin

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps 
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif

# Use these flags to add more DDR banks
#CLFLAGS += --sp multiexp_kernel_1.point_p:DDR[0:3] --sp multiexp_kernel_1.result_p:DDR[0:3] --sp multiexp_kernel_1.scalar_p:DDR[0:3]

# Place in SLR1
CLFLAGS += --slr $(KERNEL_NAME):SLR1

ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif

.PHONY: all clean cleanall $(BUILD_DIR) build run to_f1

exe: $(EXECUTABLE)

build: $(KERNEL_XCL)

all: build exe run

# Building kernel
$(KERNEL_XCL): $(BINARY_CONTAINER_vadd_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) -o'$@' $(+)

# Building Host
$(EXECUTABLE): $(HOST_SRCS)
	mkdir -p $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(HOST_INC) $(HOST_SRCS) -o '$@' $(LDFLAGS)

# Running the program
run: $(EXECUTABLE) $(KERNEL_XCL)
ifeq ($(TARGET),hw_emu)
	cd $(BUILD_DIR); XCL_EMULATION_MODE=hw_emu ../$(EXECUTABLE) ../$(KERNEL_XCL) 0x20
else
	cd $(BUILD_DIR); $(EXECUTABLE) ../$(KERNEL_XCL) 0x10000
endif 

# Gather files needed to run on the FPGA
to_f1: TARGET = hw
to_f1: $(F1_FILE)
 
$(F1_FILE): $(EXECUTABLE) $(BINARY_CONTAINER_AWS) 
	tar czvf $(F1_FILE) $(BINARY_CONTAINER_AWS) $(EXECUTABLE)

# This takes the output FPGA files and creates an AFI to run on AWS FPGA hosts
$(BINARY_CONTAINER_AWS): $(KERNEL_XCL)
	cd $(BUILD_DIR); \
	$(AWS_FPGA_REPO_DIR)/Vitis/tools/create_vitis_afi.sh -xclbin=../$(KERNEL_XCL) -o=$(KERNEL_NAME)_hw -s3_bucket=$(S3_BUCKET) -s3_dcp_key=dcp -s3_logs_key=logs; \
	cat *afi_id.txt
  
clean:
	rm -fr $(BUILD_DIR)/*hw_emu* $(EXECUTABLE)

cleanall: clean
	rm -fr $(BUILD_DIR)
