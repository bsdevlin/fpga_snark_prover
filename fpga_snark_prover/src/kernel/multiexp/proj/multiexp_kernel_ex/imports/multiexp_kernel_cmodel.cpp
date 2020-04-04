// This is a generated file. Use and modify at your own risk.
////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
// kernel: multiexp_kernel
//
// Purpose: This is a C-model of the RTL kernel intended to be used for cpu
//          emulation.  It is designed to only be functionally equivalent to
//          the RTL Kernel.
//-----------------------------------------------------------------------------
#define WORD_SIZE 32
#define SHORT_WORD_SIZE 16
#define CHAR_WORD_SIZE 8
// Transfer size and buffer size are in words.
#define TRANSFER_SIZE_BITS WORD_SIZE*4096*8
#define BUFFER_WORD_SIZE 8192
#include <string.h>
#include <stdbool.h>
#include "hls_half.h"
#include "ap_axi_sdata.h"
#include "hls_stream.h"


// Function declaration/Interface pragmas to match RTL Kernel
extern "C" void multiexp_kernel (
    double num_in,
    int* point_p,
    int* scalar_p,
    int* result_p
) {

    #pragma HLS INTERFACE m_axi port=point_p offset=slave bundle=point
    #pragma HLS INTERFACE m_axi port=scalar_p offset=slave bundle=scalar
    #pragma HLS INTERFACE m_axi port=result_p offset=slave bundle=result
    #pragma HLS INTERFACE s_axilite port=num_in bundle=control
    #pragma HLS INTERFACE s_axilite port=point_p bundle=control
    #pragma HLS INTERFACE s_axilite port=scalar_p bundle=control
    #pragma HLS INTERFACE s_axilite port=result_p bundle=control
    #pragma HLS INTERFACE s_axilite port=return bundle=control
    #pragma HLS INTERFACE ap_ctrl_hs port=return

// Modify contents below to match the function of the RTL Kernel
    unsigned int data;

    // Create input and output buffers for interface point
    int point_input_buffer[BUFFER_WORD_SIZE];
    int point_output_buffer[BUFFER_WORD_SIZE];


    // length is specified in number of words.
    unsigned int point_length = 4096;


    // Assign input to a buffer
    memcpy(point_input_buffer, (int*) point_p, point_length*sizeof(int));

    // Add 1 to input buffer and assign to output buffer.
    for (unsigned int i = 0; i < point_length; i++) {
      point_output_buffer[i] = point_input_buffer[i]  + 1;
    }

    // assign output buffer out to memory
    memcpy((int*) point_p, point_output_buffer, point_length*sizeof(int));


    // Create input and output buffers for interface scalar
    int scalar_input_buffer[BUFFER_WORD_SIZE];
    int scalar_output_buffer[BUFFER_WORD_SIZE];


    // length is specified in number of words.
    unsigned int scalar_length = 4096;


    // Assign input to a buffer
    memcpy(scalar_input_buffer, (int*) scalar_p, scalar_length*sizeof(int));

    // Add 1 to input buffer and assign to output buffer.
    for (unsigned int i = 0; i < scalar_length; i++) {
      scalar_output_buffer[i] = scalar_input_buffer[i]  + 1;
    }

    // assign output buffer out to memory
    memcpy((int*) scalar_p, scalar_output_buffer, scalar_length*sizeof(int));


    // Create input and output buffers for interface result
    int result_input_buffer[BUFFER_WORD_SIZE];
    int result_output_buffer[BUFFER_WORD_SIZE];


    // length is specified in number of words.
    unsigned int result_length = 4096;


    // Assign input to a buffer
    memcpy(result_input_buffer, (int*) result_p, result_length*sizeof(int));

    // Add 1 to input buffer and assign to output buffer.
    for (unsigned int i = 0; i < result_length; i++) {
      result_output_buffer[i] = result_input_buffer[i]  + 1;
    }

    // assign output buffer out to memory
    memcpy((int*) result_p, result_output_buffer, result_length*sizeof(int));


}

