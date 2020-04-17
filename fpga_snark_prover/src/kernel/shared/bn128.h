/*
  This provides helper functions for interfacing with the FPGA kernels and transforming
  data into and out of Montgomery and/or Jacobian form coordinates.

  We also implement some basic elliptic curve operations that can be used for verification.

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

	typedef mpz_t fe_t;

	typedef struct {
		fe_t x;
		fe_t y;
		fe_t z;
	} jb_fp_t;

	typedef struct {
		fe_t x;
		fe_t y;
	} af_fp_t;

	af_fp_t G1_mont_af;

private:
	fe_t reducer;
	fe_t mask;
	fe_t factor;
	fe_t converted_one;
	fe_t reciprocal_sq;
	fe_t reciprocal;
	fe_t modulus;
	fe_t const_2;
	fe_t const_3;
	af_fp_t G1_af;
public:
	/* The constructor sets up the montgomery values */
	Bn128();

	/* Point multiplication. Coordinates are in Montgomery form.  */
	af_fp_t result pt_mul(af_fp_t p, int n);

	/* Convert a af_fp_t to jb_fp_t */
	void af_to_jb(af_fp_t af, jb_fp_t &jb);

	/* Do an inversion and convert from jb back into af coordinates.
	   Both must be in Montgomery coordinates. Returns -1 if there was an error an no inverse
	   exists, otherwise returns 0. */
	void jb_to_af(jb_fp_t jb, af_fp_t &af);

    /* Convert a af_fp_t into a af_fp_t where the points are encoded in Montgomery form */
	void af_to_mont(af_fp_t af, af_fp_t &af_mont);

    /* Convert a af_fp_t encoded in Montgeromy form back into a normal af point */
	void af_from_mont(af_fp_t af_mont, af_fp_t &af);

	/* Takes a void pointer and exports the data in a af_fp_t to it */
	void af_export(void* data, af_fp_t af);

	/* Takes a jb_fp_t and fills it with data from a void pointer */
	void jb_import(jb_fp_t &jb, void* data);

	/* Print a af_fp_t point's coordinates */
	void print_af(af_fp_t af);
	
	/* Print a jb_fp_t point's coordinates */
	void print_jb(jb_fp_t jb);

private:
	/* Montgomery multiplication */
	void mont_mult(mpz_t &result, mpz_t op1, mpz_t op2);

	/* Convert into Montgomery form */
	void to_mont(mpz_t &result);

	/* Convert from Montgomery form */
	void from_mont(mpz_t &result);

	/* Point addition in affine coordinates. Coordinates are in Montgomery form. */
	void pt_add(af_fp_t &result, af_fp_t p, af_fp_t q);

	/* Point doubling in affine coordinates. Coordinates are in Montgomery form. */
	void pt_dbl(af_fp_t &result, af_fp_t p);

	/* Arithmetic on G1 field elements in Montgomery form */
	void mul(fe_t &result, fe_t a, fe_t b);
	void add(fe_t &result, fe_t a, fe_t b);
	void sub(fe_t &result, fe_t a, fe_t b);
};

#endif
