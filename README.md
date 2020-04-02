This repo contains the results of an Ethereum grant into developing a FPGA SNARK prover. The project is still in progress.

# Project goals

The goal of this project is to accelerate zk-SNARK proof creation by offloading operations to a FPGA. The project deliverables are split into 3 main goals:
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