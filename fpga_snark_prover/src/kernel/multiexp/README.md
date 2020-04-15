Multi-exponentiation in G1 
======================

## Kernel base performance and area utilization
The kernel when synthesized for a single core and single arithmetic unit  are shown below (bracket values are % of a VU9P AWS FPGA).
Other resource types (BRAMs, LUTRAMs, etc) are not shown because their usage is very low. This includes glue logic of the kernel, and won't include the other top level logic AWS inserts, so is just a rough guide.

| FF |  LUT | DSP| 
| --- | --- | --- |
| 70031 (3.96) | 92245 (7.80) | 450 (6.58) |

The core was able to operate at 290MHz and took 1115085 clock cycles, 8294 point/s.

Each core adds ~10.5K FFs and ~12.5K LUTs. Each arithmetic unit adds ~50K FFs, 23K LUTs, and 480 DSPs.

## Simulated performance
The table below shows the performance and area trade off when increasing cores or increasing arithmetic units. FMax here shows the maximum frequency that was acheived during a 
out of context run, and due to quantization effects when assembling multiple kernels might change. Throughput was simulated over a small number of points (32), but it is enough to 
saturate the cores operating in parallel, so that performance would roughly be linear with increase of input points.

| Number of Cores | Number of Arithmetic units | Throughput (point/s) | 
| --- | --- | --- | 
| 1 | 1 | 8.294K | 
| 2 | 1 | 11.112K | 
| 4 | 1 | 17.512K | 
| 4 | 2 | 17.720K | 
| 8 | 1 | 29.051K | 
| 8 | 2 | 31.676K | 
| 16 | 1 | 44.558K | 
| 16 | 2 | 47.393K | 
| 32 | 1 | 48.945K |
| 32 | 2 | 69.487K |
It seems you probably want around 1 arithmetic unit per 16 cores to avoid losing performance. After ~30 cores the LUT usage forces the placement to be spanning super logic regions (SLRs), and performance is impacted heavily. So the kernel was programmed with 16 cores and 1 arithmetic unit.