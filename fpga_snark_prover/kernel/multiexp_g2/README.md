Multi-exponentiation in G2
======================

This kernel is similar to the multiexp_g1 block, except because the data path is so much wider and requires more logic on the FPGA, uses a streaming architecture where busses are all 256 bits.

Each core operates on a subset of the inputs (Mongomery form Jacobian coordinates and scalar pairs), and the inputs are read in a streaming loop. 
The kernel default is compiled with 8 cores, so each core will get 1/8 of the total inputs. After each core has its final result, they are collapsed into each other log2 - so in the case of 8 cores there would be another 3 stages of point addition done before the final Montgomery form Jacobian coordinate point is streamed back to host.
