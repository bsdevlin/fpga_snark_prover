FPGA SNARK prover targeting the bn128 curve.
======================

This repo contains the results of an Ethereum grant into developing a FPGA SNARK prover. The project is still in progress.

## Project goals ##

The goal of this project is to accelerate zk-SNARK proof creation by offloading operations to a FPGA:
 * FPGA acceleration of bn128 curve arithmetic
   - Implement base curve arithmetic in Montgomery form, coprocessor architecture
   - Implement G1 (Fp) & G2 (Fp2) point multiplication
   - Implement architecture on AWS and show functionality with c++ API over PCIe
 * Multi exponentiation (multiexp) - implement G1_MULTIEXP and G2_MULTIEXP
   - Modify point multiplication architecture from #1 on FPGA utilizing some method to accelerate multiple parallel point multiplications (e.g. utilize window / NAF / pre calculation)
   - Implement G1_MULTIEXP
   - Implement G2_MULTIEXP
 * QAP evaluation - (i)FFT - implements CALC_H and all sub operations
   - Implement polynomial field arithmetic on FPGA
   - Implement the FFT / iFFT on FPGA
   

## Folder structure ##

```
fpga_snark_prover/  -- Files directly related to this project.
ip_cores/           -- RTL ip cores for general use in this project.
submodules/         -- Git submodules that reference other repositories.**
```

** Make sure you have synced the git submodules folder in ```fpga_snark_prover/submodules/``` with "git submodule update".

Each goal will have a corresponding RTL top level and source in the ```fpga_snark_prover``` folder which can be ran separately, as well as a RTL kernel 
pre-compiled (along with instructions to compile the binary if needed). The kernels will be able to run in a Amazon AWS Vivado Vitis (SDAccel) environment as accelerators,
interfaced to user logic (look in ```fpga_snark_prover\kernel``` to see this). The kernels have access to 4x 16GB DDR4 banks when run on Amazon AWS F1 FPGA instances.

You can also use Vivado to modify and simulate the RTL by creating a project and adding all the sources from each folder, and then running the testbenches in the /tb/ folders.

