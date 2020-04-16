/*
  This provides helper functions for interfacing with the FPGA kernels and transforming
  data into and out of Montgomery and/or Jacobian form coordinates.

  We also implement some basic eliptic curve operations that can be used for verification.

  Copyright (C) 2019  Benjamin Devlin

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#ifndef BN128_H
#define BN128_H

#include <gmp.h>

#define BN128_BITS 256
#define BN128_MODULUS "21888242871839275222246405745257275088696311157297823662689037894645226208583"
#define G1_X "1"
#define G1_Y "2"

class Bn128 {
public:
	typedef struct {
		mpz_t x;
		mpz_t y;
		mpz_t z;
	} jb_fp_t;

	typedef struct {
		mpz_t x;
		mpz_t y;
	} af_fp_t;

	af_fp_t G1_af;
	af_fp_t G1_mont_af;

protected:
	mpz_t reducer;
	mpz_t mask;
	mpz_t factor;
	mpz_t converted_one;
	mpz_t reciprocal_sq;
	mpz_t reciprocal;
	mpz_t modulus;
public:
	/* The constructor sets up the montgomery values */
	Bn128 ();

	/* Montgomery multiplication */
	void mont_mult(mpz_t &result, mpz_t op1, mpz_t op2);

	/* Convert into Montgomery form */
	void to_mont(mpz_t &result);

	/* Convert from Montgomery form */
	void from_mont(mpz_t &result);

	/* Convert a af_fp_t to jb_fp_t */
	void af_to_jb(af_fp_t af, jb_fp_t &jb);

    /* Convert a af_fp_t into a af_fp_t where the points are incoded in Montgomery form */
	void af_to_mont(af_fp_t af, af_fp_t &af_mont);

	/* Takes a void pointer and exports the data in a af_fp_t to it */
	void af_export (void* data, af_fp_t af);

	/* Takes a jb_fp_t and fills it with data from a void pointer */
	void jb_import (jb_fp_t &jb, void* data);

	/* Print a af_fp_t point's coordinates */
	void print_af(af_fp_t af);
	
	/* Print a jb_fp_t point's coordinates */
	void print_jb(jb_fp_t jb);
};

#endif
