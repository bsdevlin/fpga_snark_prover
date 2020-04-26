Kernels (RTL)
======================

Several kernels have been compiled from the RTL code that allows for easy inclusion into a host.cpp file. Multiple kernels can be linked and 
exercised depending on what functionality is needed.
Each kernels operates on DRAM memory on the FPGA, which has 4 DDR banks of 16GB each. When building the kernel will automatically get assigned to a 16GB DDR bank and only able to access that bank - to change this you need to modify the kernel.cdf file.

Each kernel has a **hw_emu** and **hw** makefile targets. 
The **hw_emu** target create a ``build_output/<kernel_name>.xclbin`` file and runs hardware simulation which will verify the design against the host.cpp. This takes around 5min to build.
The **hw** target will build the ``build_output/<kernel_name>.xclbin`` and ``.awsxclbin`` file which is used to create an AFI for use on Amazon AWS F1 instances with real hardware. This takes around 4 hours to build.

For more information please see [here](https://github.com/aws/aws-fpga/tree/master/Vitis). This document goes over the accelerator platform and different configuration settings you can change in the kernel.cfg file: [Vitis Unified Software
Platform Documentation](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2019_2/ug1393-vitis-application-acceleration.pdf).

Each kernel folder contains the following files:

```
src/host.cpp                   -- The top level host file that shows example usage and test of the kernel
src/kernel.cfg                 -- Kernel config options, here the SLR or DDR banks assigned can be changed
src/kernel.xml                 -- XML describing the kernel, do not change
src/hdl/*                      -- RTL files used to generate the kernel logic
scripts/*                      -- Scripts used to generate output files, do not change
README.md                      -- Kernel specific readme
Makefile, utils.mk             -- Makefiles
xrt.ini                        -- Used during testing with TARGET=hw_emu, you can uncomment the two lines to be able to see the simulation waveform
```

## To run ##

1. ``source fpga_snark_prover\submodules\aws-fpga\vitis_setup.sh``.
2. Go into one of the kernel directories, and run hardware emulation ``make all TARGET=hw_emu``.
3. Build the .xclbinmage that will be loaded onto the FPGA ``make all TARGET=hw``.
4. Build the .awsxclbin and AFI. ``make to_f1 S3_BUCKET=<S3 name of your bucket>``. This will generate a tar 'to_f1.tar.gz' that can be copied onto a F1 instance and run on a real FPGA.


##  Kernel overview ##
###  Multiexp_g1 ###
Calculates the G1 multi-exponentiation. 

| # | Argument | Type | Notes |
| --- | --- | --- | --- |
| 0 | num_in  | uint64_t  | The number of points in G1 and scalars pairs to operate on. Must be a multiple of the number of cores (16).   |
| 1 | point_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of input G1 points in Montgomery form affine coordinates. |
| 2 | scalar_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of 256 bit scalars. |
| 3 | result_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_WRITE_ONLY  | The pointer to memory to write the resulting G1 Montgomery form jacobian point coordinates. |

###  Multiexp_g2
Calculates the G2 or G1 multi-exponentiation. 

| # | Argument | Type | Notes |
| --- | --- | --- | --- |
| 0 | num_in  | uint64_t  | The number of points in G2 and scalars to operate on. Must be a multiple of the number of cores (16).   |
| 1 | point_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of input G2 points in Montgomery form affine coordinates. |
| 2 | scalar_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of 256 bit scalars. |
| 3 | result_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_WRITE_ONLY  | The pointer to memory to write the resulting G2 Montgomery form jacobian point coordinates. |
