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
	$(ECHO)  "  make test"
	$(ECHO)  "     Command to run the application. This is same as 'check' target but does not have any makefile dependency."
	$(ECHO)  ""
	$(ECHO) "  make check"
	$(ECHO) "      Command to run application in emulation."
	$(ECHO) ""
	$(ECHO) "  make build TARGET=<hw_emu/hw>"
	$(ECHO) "      Command to build xclbin application."
	$(ECHO) ""
	$(ECHO) "  make to_f1 S3_BUCKET=<S3 name of your bucket> TARGET=hw"
	$(ECHO) "      Command to create the AFI and .awsxclbin required to run on the AWS FPGA. You need to have a S3 bucket to upload files to. Only works with hw target."	
	$(ECHO) ""
	
# Points to top directory of Git repository
COMMON_REPO = $(AWS_FPGA_REPO_DIR)/Vitis/examples/xilinx/
PWD = $(shell readlink -f .)
ABS_COMMON_REPO = $(shell readlink -f $(COMMON_REPO))

TARGET = hw_emu
HOST_ARCH := x86
SYSROOT := 
DEVICE := $(AWS_PLATFORM)
DEBUG = no

include ./utils.mk

XSA := $(call device2xsa, $(DEVICE))
TEMP_DIR = ./_x.$(TARGET).$(XSA)
BUILD_DIR = ./build_dir.$(TARGET).$(XSA)

VPP := v++

#Include Libraries
include $(ABS_COMMON_REPO)/common/includes/opencl/opencl.mk
include $(ABS_COMMON_REPO)/common/includes/xcl2/xcl2.mk
CXXFLAGS += $(xcl2_CXXFLAGS)
LDFLAGS += $(xcl2_LDFLAGS) -lgmp -lgmpxx
HOST_SRCS += $(xcl2_SRCS)
HOST_SRCS += src/host.cpp
HOST_INC := -I../shared/

CXXFLAGS += $(opencl_CXXFLAGS) -Wall -O0 -g -std=c++11
LDFLAGS += $(opencl_LDFLAGS)

# Host compiler global settings
CXXFLAGS += -fmessage-length=0
LDFLAGS += -lrt -lstdc++ 

ifneq ($(HOST_ARCH), x86)
	LDFLAGS += --sysroot=$(SYSROOT)
endif

# Kernel compiler global settings
CLFLAGS += -t $(TARGET) --platform $(DEVICE) --save-temps
ifneq ($(TARGET), hw)
	CLFLAGS += -g
endif


EXECUTABLE = host
KERNEL_NAME = multiexp_g1_kernel
CMD_ARGS = $(BUILD_DIR)/$(KERNEL_NAME).xclbin
EMCONFIG_DIR = $(TEMP_DIR)
EMU_DIR = $(SDCARD)/data/emulation

CLFLAGS += --config src/kernel.cfg

BINARY_CONTAINERS += $(BUILD_DIR)/$(KERNEL_NAME).xclbin
BINARY_CONTAINER_OBJS += $(TEMP_DIR)/$(KERNEL_NAME).xo

BINARY_CONTAINER_AWS = $(KERNEL_NAME).awsxclbin
F1_FILE := to_f1.tar.gz
S3_BUCKET := your_bucket_name


ifeq ($(DEBUG),yes)
	LDCLFLAGS += --dk chipscope:multiexp_g1_kernel_1 --xp "param:chipscope.enablePRFlow=true"
endif

CP = cp -rf

.PHONY: all clean cleanall docs emconfig
all: check-devices $(EXECUTABLE) $(BINARY_CONTAINERS) emconfig

.PHONY: exe
exe: $(EXECUTABLE)

.PHONY: build
build: $(BINARY_CONTAINERS)

VIVADO := $(XILINX_VIVADO)/bin/vivado

$(TEMP_DIR)/$(KERNEL_NAME).xo: src/kernel.xml scripts/package_kernel.tcl scripts/gen_xo.tcl src/hdl/*.sv src/hdl/*.v 
	mkdir -p $(TEMP_DIR)
	$(VIVADO) -mode batch -source scripts/gen_xo.tcl -tclargs $(TEMP_DIR)/$(KERNEL_NAME).xo $(KERNEL_NAME) $(TARGET) $(DEVICE) $(XSA)

# Building kernel
$(BUILD_DIR)/$(KERNEL_NAME).xclbin: $(BINARY_CONTAINER_OBJS)
	mkdir -p $(BUILD_DIR)
	$(VPP) $(CLFLAGS) --temp_dir $(BUILD_DIR) -l $(LDCLFLAGS) -o'$@' $(+)

# Building Host
$(EXECUTABLE): check-xrt $(HOST_SRCS) $(HOST_HDRS)
	$(CXX) $(CXXFLAGS) $(HOST_INC) $(HOST_SRCS) $(HOST_HDRS) -o '$@' $(LDFLAGS)

emconfig:$(EMCONFIG_DIR)/emconfig.json
$(EMCONFIG_DIR)/emconfig.json:
	emconfigutil --platform $(DEVICE) --od $(EMCONFIG_DIR)

NUM_IN :=
EMU_MODE :=
ifeq ($(TARGET), hw_emu)
	NUM_IN := 0x10
	EMU_MODE := XCL_EMULATION_MODE=$(TARGET)
else
	NUM_IN := 0x10000
	EMU_MODE :=
endif

# Gather files needed to run on the FPGA
.PHONY: to_f1
to_f1: $(F1_FILE)
$(F1_FILE): $(EXECUTABLE) $(BINARY_CONTAINER_AWS)
	tar czvf $(F1_FILE) $(BINARY_CONTAINER_AWS) $(EXECUTABLE) *afi_id.txt



# This takes the output FPGA files and creates an AFI to run on AWS FPGA hosts
$(BINARY_CONTAINER_AWS): $(BUILD_DIR)/$(KERNEL_NAME).xclbin
ifneq ($(TARGET), hw)
	$(error TARGET must be hw)
else
	$(AWS_FPGA_REPO_DIR)/Vitis/tools/create_vitis_afi.sh -xclbin=$(BUILD_DIR)/$(KERNEL_NAME).xclbin -o=$(KERNEL_NAME) -s3_bucket=$(S3_BUCKET) -s3_dcp_key=dcp -s3_logs_key=logs; \
	cat *afi_id.txt
endif

check: TARGET = hw_emu
check: all
	$(CP) $(EMCONFIG_DIR)/emconfig.json .
	$(EMU_MODE) ./$(EXECUTABLE) $(BUILD_DIR)/$(KERNEL_NAME).xclbin $(NUM_IN) 1

.PHONY: test
test: $(EXECUTABLE)
	$(EMU_MODE) ./$(EXECUTABLE) $(BUILD_DIR)/$(KERNEL_NAME).xclbin $(NUM_IN) 1

ifneq ($(TARGET),$(findstring $(TARGET), hw hw_emu))
$(warning WARNING:Application supports only hw hw_emu TARGET. Please use the target for running the application)
endif

# Cleaning stuff
clean:
	-$(RMDIR) $(EXECUTABLE) $(XCLBIN)/{*sw_emu*,*hw_emu*} 
	-$(RMDIR) profile_* TempConfig system_estimate.xtxt *.rpt *.csv 
	-$(RMDIR) src/*.ll *v++* .Xil emconfig.json dltmp* xmltmp* *.log *.jou *.wcfg *.wdb

cleanall: clean
	-$(RMDIR) build_dir* $(F1_FILE) *.txt *.json *bin *.dcp *.tar
	-$(RMDIR) _x.* *xclbin.run_summary qemu-memory-_* emulation/ _vimage/ pl* start_simulation.sh *.xclbin
	-$(RMDIR) ./tmp_kernel_pack* ./packaged_kernel* 
