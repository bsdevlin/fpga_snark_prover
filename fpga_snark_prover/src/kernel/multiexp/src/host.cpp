/**********
Copyright (c) 2019, Xilinx, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software
without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**********/
#include "xcl2.hpp"
#include "bn128.hpp"
#include <vector>



int main(int argc, char **argv) {
    if (argc != 2) {
        std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << std::endl;
        return EXIT_FAILURE;
    }

	uint64_t num_in = 16;

    std::string binaryFile = argv[1];

   Bn128 bn128;

    cl_int err;
    cl::CommandQueue q;
    cl::Context context;
    cl::Kernel krnl;
    
    //Allocate Memory in Host Memory
    size_t scalar_vector_size_bytes = BN128_BITS/8 * num_in;
    size_t point_vector_size_bytes = 2 * BN128_BITS/8 * num_in;
    size_t result_vector_size_bytes = 3 * BN128_BITS/8; // Result is in jb
    
    std::vector<uint64_t, aligned_allocator<uint64_t>> scalar_input(scalar_vector_size_bytes/8);
    std::vector<uint64_t, aligned_allocator<uint64_t>> point_input(point_vector_size_bytes/8);
    std::vector<uint64_t, aligned_allocator<uint64_t>> hw_result(result_vector_size_bytes/8);
//    std::vector<uint64_t, aligned_allocator<uint64_t>> source_sw_results(result_vector_size_bytes/8);

    memset((void*)scalar_input.data(), 0, num_in*BN128_BITS/8);

//bn128.print_af(bn128.G1_mont_af);

    // Create the test data and Software Result
    for (size_t i = 0; i < num_in; i++) {
        bn128.af_export((void*)&point_input[i*2*BN128_BITS/64], bn128.G1_mont_af);
        scalar_input[i*BN128_BITS/64] = 1 + i;
      //  source_sw_results[i] = source_input1[i] + source_input2[i];
    }

//bn128.print_af(*((Bn128::af_fp_t*)((void*)point_input.data())));

  //bn128.af_export_64((void*)point_input.data(), bn128.G1_mont_af);
  //  for (size_t i = 0; i < 32; i++) {
  //      printf("0x%lx\n", point_input[i]);
  //  }


    memset((void*)hw_result.data(), 0, result_vector_size_bytes);

    //OPENCL HOST CODE AREA START
    //Create Program and Kernel
    auto devices = xcl::get_xil_devices();

    // read_binary_file() is a utility API which will load the binaryFile
    // and will return the pointer to file buffer.
    auto fileBuf = xcl::read_binary_file(binaryFile);
    cl::Program::Binaries bins{{fileBuf.data(), fileBuf.size()}};
    int valid_device = 0;
    for (unsigned int i = 0; i < devices.size(); i++) {
        auto device = devices[i];
        // Creating Context and Command Queue for selected Device
        OCL_CHECK(err, context = cl::Context({device}, NULL, NULL, NULL, &err));
        OCL_CHECK(err,
                  q = cl::CommandQueue(
                      context, {device}, CL_QUEUE_PROFILING_ENABLE, &err));

        std::cout << "Trying to program device[" << i
                  << "]: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;
                  cl::Program program(context, {device}, bins, NULL, &err);
        if (err != CL_SUCCESS) {
            std::cout << "Failed to program device[" << i
                      << "] with xclbin file!\n";
        } else {
            std::cout << "Device[" << i << "]: program successful!\n";
            OCL_CHECK(err,
                      krnl = cl::Kernel(program, "multiexp_kernel", &err));
            valid_device++;
            break; // we break because we found a valid device
        }
    }
    if (valid_device == 0) {
        std::cout << "Failed to program any device found, exit!\n";
        exit(EXIT_FAILURE);
    }

    //Allocate Buffer in Global Memory
    OCL_CHECK(err,
              cl::Buffer buffer_scalar(context,
                                   CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
                                   scalar_vector_size_bytes,
                                   scalar_input.data(),
                                   &err));
    OCL_CHECK(err,
              cl::Buffer buffer_point(context,
                                   CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
                                   point_vector_size_bytes,
                                   point_input.data(),
                                   &err));
    OCL_CHECK(err,
              cl::Buffer buffer_result(context,
                                  CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY,
                                  result_vector_size_bytes,
                                  hw_result.data(),
                                  &err));

    //Set the Kernel Arguments
    OCL_CHECK(err, err = krnl.setArg(0, num_in));
    OCL_CHECK(err, err = krnl.setArg(1, buffer_point));
    OCL_CHECK(err, err = krnl.setArg(2, buffer_scalar));
    OCL_CHECK(err, err = krnl.setArg(3, buffer_result));

    //Copy input data to device global memory
    OCL_CHECK(err,
              err = q.enqueueMigrateMemObjects({buffer_point, buffer_scalar},
                                               0 /* 0 means from host*/));

    //Launch the Kernel
    OCL_CHECK(err, err = q.enqueueTask(krnl));

    //Copy Result from Device Global Memory to Host Local Memory
    OCL_CHECK(err,
              err = q.enqueueMigrateMemObjects({buffer_result},
                                               CL_MIGRATE_MEM_OBJECT_HOST));
    OCL_CHECK(err, err = q.finish());

    //OPENCL HOST CODE AREA END

    printf("Result=");

  for (size_t i = 0; i < 12; i++) {
        printf("0x%lx\n", hw_result[i]);
    }

Bn128::jb_fp_t res_p;
//mpz_init(res_p.x);
//mpz_init(res_p.y);
//mpz_init(res_p.z);
bn128.jb_import(res_p, hw_result.data());
bn128.print_jb(res_p);

//	bn128.print_af(*((Bn128::af_fp_t*)((void*)&hw_result[0])));


//	bn128.print_jb(*((Bn128::jb_fp_t*)((void*)hw_result.data())));

    return EXIT_SUCCESS;
}
