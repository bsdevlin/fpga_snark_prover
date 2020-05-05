Multi-exponentiation in G2
======================
Please refer to the multiexp_g1 architecture description as the multiexp_g2 kernel is very similar. The only difference is packet data passed around is twice as big (for c0 and c1 coefficients), and the multiplier block has an extra interface block to convert the fe2 multiplications into fe1 multiplications.  Currently the number of cores needs to be a power of two.


![Multiexp G2 core architecture](../images/multiexp_g2_core_architecture.png)

## Area utilization ##

The kernel was able to operate at 250MHz with 8 cores. The top level (including multiplier and kernel glue logic) used the following resources:

| FF |  LUT | DSP| 
| --- | --- | --- |
| 226590 (9.58%) | 166786 (14.11%) | 480 (7.02%) |

Each multiexp G2 core uses:

| FF |  LUT |  
| --- | --- | 
| 379269 (16.04%) | 267207 (22.60%) | 480 (7.02%) |

## Performance ##

The measured performance of the kernel with 8 cores to performance a multi-exponentiation in G2 over 2^20 points and randomly generated scalars was 52s, 20.1K op/s, or 2.5K op/s/core (For reference a 4 core kernel had performance of 3.1K op/s/core, so the multiplier might be getting fully utilized here). 
