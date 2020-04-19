Kernels (RTL)
======================

Several kernels have been compiled from the RTL code that allows for easy inclusion into a host.cpp file. Multiple kernels can be linked and 
exercised depending on what functionality is needed.
Each kernels operates on DRAM memory on the FPGA, which has 4 DDR banks of 16GB each. 
Each kernel has a **hw_emu** and **hw** makefile targets. 
The **hw_emu** target create a ``build_output/<kernel_name>.xclbin`` file and runs hardware simulation which will verify the design against the host.cpp. This takes around 5min to build.
The **hw** target will build the ``build_output/<kernel_name>.xclbin`` and ``.awsxclbin`` file which is used to create an AFI for use on Amazon AWS F1 instances with real hardware. This takes around 4 hours to build.

For more information please see [here](https://github.com/aws/aws-fpga/tree/master/Vitis).

Each kernel folder contains the following files:

```
src/host.cpp                   -- The top level host file that that runs the kernel
bin/<kernel_name>_kernel.xo    -- The binary kernel file that has been pre-compiled for linking into the application
proj/create_project.tcl        -- The Vivado 2019.2 project creation file that can be used to re-create the project and create the kernel binary .xo file
README.md                      -- Kernel specific readme
```

## To run ##

1. ``source fpga_snark_prover\submodules\aws-fpga\vitis_setup.sh``.
2. Go into one of the kernel directories, and run hardware emulation ``make all TARGET=hw_emu``.
3. Build the .xclbinmage that will be loaded onto the FPGA ``make all TARGET=hw``.
4. Build the .awsxclbin and AFI. ``make to_f1 S3_BUCKET=<S3 name of your bucket>`` This will generate a tar 'to_f1.tar.gz' that can be copied onto a F1 instance and run on a real FPGA.

When building the kernel will automatically get assigned to a 16GB DDR bank and only able to access that bank - to change this you need to uncomment the ``CLFLAGS += --sp ...`` lines.

##  Kernel overview ##
###  Multiexp ###
Calculates the G1 multi-exponentiation. 

| # | Argument | Type | Notes |
| --- | --- | --- | --- |
| 0 | num_in  | uint64_t  | The number of points/scalars to operate on.   |
| 1 | point_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of input G1 points in affine coordinates. |
| 2 | scalar_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_READ_ONLY  | The pointer to memory of 256 bit scalars. |
| 3 | result_p  | cl::Buffer with CL_MEM_USE_HOST_PTR, CL_MEM_WRITE_ONLY  | The pointer to memory to write the resulting G1 point in jacobian coordinates. |

###  Multiexp
Calculates the G2 or G1 multi-exponentiation. 