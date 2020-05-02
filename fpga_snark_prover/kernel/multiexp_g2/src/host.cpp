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
#include <time.h>

/*
 This shows an example of using the multiexp g2 kernel to take num_in
 inputs and perform multi exponentiation over that many points.
 The output is printed and checked at the end.
 */

// Start a nanosecond-resolution timer
struct timespec timer_start(){
    struct timespec start_time;
    clock_gettime(CLOCK_REALTIME, &start_time);
    return start_time;
}

// End a timer, returning nanoseconds elapsed as a long
long timer_end(struct timespec start_time){
    struct timespec end_time;
    clock_gettime(CLOCK_REALTIME, &end_time);
    long diffInNanos = (end_time.tv_sec - start_time.tv_sec) *
        (long)1e9 + (end_time.tv_nsec - start_time.tv_nsec);
    return diffInNanos;
}

int main(int argc, char **argv) {
	if (argc != 4) {
		std::cout << "Usage: " << argv[0] << " <XCLBIN File>" << " <number of points to test>" << " <0 or 1 to enable software verification>" << std::endl;
		return EXIT_FAILURE;
	}

	std::string binaryFile = argv[1];
	uint64_t num_in = strtol(argv[2], NULL, 0);
	bool check_result = strtol(argv[3], NULL, 0);

	cl_int err;
	cl::CommandQueue q;
	cl::Context context;
	cl::Kernel krnl;
	Bn128::init();

	//Allocate Memory in Host Memory
	size_t scalar_vector_size_bytes = BN128_BITS/8 * num_in;
	size_t point_vector_size_bytes = 2 * 2 * BN128_BITS/8 * num_in;
	size_t result_vector_size_bytes = 2 * 3 * BN128_BITS/8; // Result is fp2 in jb in Montgomery form

	std::vector<uint64_t, aligned_allocator<uint64_t>> scalar_input(scalar_vector_size_bytes/8);
	std::vector<uint64_t, aligned_allocator<uint64_t>> point_input(point_vector_size_bytes/8);
	std::vector<uint64_t, aligned_allocator<uint64_t>> hw_result(result_vector_size_bytes/8);

	Bn128::af_p_t<Bn128::f_t<2>> sw_result;
	sw_result = 0;

	// Create the test data - random scalars with uniform distribution
	gmp_randstate_t random_state;
	gmp_randinit_default(random_state);
	for (size_t i = 0; i < num_in; i++) {
		mpz_t s;
		mpz_init(s);
		mpz_urandomb(s, random_state, BN128_BITS);
		Bn128::af_p_t<Bn128::f_t<2>> p = Bn128::G2_af * s;
		Bn128::af_export((void*)&point_input[i*4*BN128_BITS/64], Bn128::to_mont(p));
		Bn128::fe_export((void*)&scalar_input[i*BN128_BITS/64], s);
		if (check_result)
			sw_result = sw_result + (p * s);
	}

	// Expected result
	if (check_result) {
		printf("Expected result:\n");
		sw_result.print();
	} else {
		printf("INFO: Not checking result in SW");
	}

	// Run the kernel

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
		OCL_CHECK(err, q = cl::CommandQueue(context, {device}, CL_QUEUE_PROFILING_ENABLE, &err));

		std::cout << "Trying to program device[" << i << "]: " << device.getInfo<CL_DEVICE_NAME>() << std::endl;
		cl::Program program(context, {device}, bins, NULL, &err);
		if (err != CL_SUCCESS) {
			std::cout << "Failed to program device[" << i << "] with xclbin file!\n";
		} else {
			std::cout << "Device[" << i << "]: program successful!\n";
			OCL_CHECK(err, krnl = cl::Kernel(program, "multiexp_g2_kernel", &err));
			valid_device++;
			break; // we break because we found a valid device
		}
	}
	if (valid_device == 0) {
		std::cout << "Failed to program any device found, exit!\n";
		exit(EXIT_FAILURE);
	}

	//Allocate Buffer in Global Memory
	OCL_CHECK(err, cl::Buffer buffer_scalar(context,
		       CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
		       scalar_vector_size_bytes,
		       scalar_input.data(),
		       &err));
	OCL_CHECK(err, cl::Buffer buffer_point(context,
		       CL_MEM_USE_HOST_PTR | CL_MEM_READ_ONLY,
		       point_vector_size_bytes,
		       point_input.data(),
		       &err));
	OCL_CHECK(err, cl::Buffer buffer_result(context,
		       CL_MEM_USE_HOST_PTR | CL_MEM_WRITE_ONLY,
		       result_vector_size_bytes,
		       hw_result.data(),
		       &err));

	// Check how many cores - 

	//Set the Kernel Arguments
	OCL_CHECK(err, err = krnl.setArg(0, num_in));
	OCL_CHECK(err, err = krnl.setArg(1, buffer_point));
	OCL_CHECK(err, err = krnl.setArg(2, buffer_scalar));
	OCL_CHECK(err, err = krnl.setArg(3, buffer_result));

	//Copy input data to device global memory
	OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer_point, buffer_scalar},	0 /* 0 means from host*/));
    	struct timespec start_ts;
	uint64_t compute_time;
    	start_ts = timer_start();
	//Launch the Kernel - start timing here
	OCL_CHECK(err, err = q.enqueueTask(krnl));


	//Copy Result from Device Global Memory to Host Local Memory
	OCL_CHECK(err, err = q.enqueueMigrateMemObjects({buffer_result},
					CL_MIGRATE_MEM_OBJECT_HOST));
	OCL_CHECK(err, err = q.finish());
	compute_time = timer_end(start_ts);

	//OPENCL HOST CODE AREA END

	Bn128::jb_p_t<Bn128::f_t<2>> res_jb;
	Bn128::jb_import(res_jb, hw_result.data());
	printf("Result from FPGA:\n");
	res_jb.print();

	Bn128::af_p_t<Bn128::f_t<2>> res_af = Bn128::mont_jb_to_af(res_jb);
	printf("Converted back to af coordinates in normal form:\n");
	res_af.print();

	if (!check_result) {
		printf("\n\nProgram finished (not checking result), took %luns for %lu input points, %f op/s.\n\n", compute_time, num_in, (1e9*num_in)/compute_time);
		return EXIT_SUCCESS;
	} else if (res_af == sw_result) {
		printf("\n\nHURRAH - Result matched expected result, took %luns for %lu input points, %f op/s.\n\n", compute_time, num_in, (1e9*num_in)/compute_time);
		return EXIT_SUCCESS;
	} else {
		printf("\n\nERROR - Result did not match\n\n");
		return EXIT_FAILURE;
	}

}
