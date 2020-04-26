Multi-exponentiation in G2
======================
Please refer to the multiexp_g1 architecture description as the multiexp_g2 kernel is very similar.

The kernel has been configured with 8 cores due to each core being larger than in the G1 case, but this could be changed and experimented with.

## Kernel base performance and area utilization ##

The kernel was able to operate at 250MHz with 8 cores. It used the following resources in total:

| FF |  LUT | DSP| 
| --- | --- | --- |
| 340337 (19.97) | 236152 (14.39) | 450 (6.58) |

Each additional core adds ~33K FFs and ~26K LUTs. Each multiplier unit adds ~50K FFs, 23K LUTs, and 480 DSPs.