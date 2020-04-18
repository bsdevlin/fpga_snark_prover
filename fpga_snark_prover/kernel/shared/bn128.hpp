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
#include <stdint.h>
#include <vector>

#define BN128_BITS 256
#define BN128_MODULUS "21888242871839275222246405745257275088696311157297823662689037894645226208583"
#define G1_X "1"
#define G1_Y "2"

class Bn128 {
public:

	struct jb_fp_t {
		mpz_t x;
		mpz_t y;
		mpz_t z;

    		bool operator==(const jb_fp_t& a) const {
        		return (mpz_cmp(x, a.x) == 0 && 
				mpz_cmp(y, a.y) == 0 &&
				mpz_cmp(z, a.z) == 0);
    		}
	};

	struct af_fp_t {
		mpz_t x;
		mpz_t y;

    		bool operator==(const af_fp_t& a) const {
        		return (mpz_cmp(x, a.x) == 0 &&
				mpz_cmp(y, a.y) == 0);
    		}
	};

	static af_fp_t G1_af;

private:
	mpz_t reducer;
	mpz_t mask;
	mpz_t factor;
	mpz_t converted_one;
	mpz_t reciprocal_sq;
	mpz_t reciprocal;
	mpz_t modulus;
public:
	/* The constructor sets up the montgomery values. */
	Bn128();

	/* Naive implementation of G1 multi exponentiation of vector of point, scalar pairs */
	af_fp_t multi_exp(std::vector<std::pair<Bn128::af_fp_t, mpz_t>> p_s);

	/* Point multiplication p by scalar s. */
	af_fp_t pt_mul(af_fp_t p, mpz_t s);

	/* Convert a af_fp_t in normal form to jb_fp_t in Montgomery form. */
	jb_fp_t to_mont_jb(af_fp_t af);

	/* Do an inversion and convert from jb in Montgomery form back into af in normal form coordinates.
	   Returns a 0 point if there was an error an no inverse exists. */
	af_fp_t mont_jb_to_af(jb_fp_t jb);
	
	/* Converts an af point into montgomery form, used for loading input into FPGA as internally we convert into jb. */
	af_fp_t to_mont_af(af_fp_t af);

	/* Takes a void pointer and exports the point data in a af_fp_t to it */
	void af_export(void* data, af_fp_t af);

	/* Takes a void pointer and exports the scalar data in a mpz_t to it */
	void fe_export(void* data, mpz_t fe);
	
	/* Takes a jb_fp_t and fills it with jb point data from a void pointer. */
	void jb_import(jb_fp_t &jb, void* data);

	/* Print a af_fp_t point's coordinates. */
	void print_af(af_fp_t af);
	
	/* Print a jb_fp_t in Montgomery form point's coordinates. */
	void print_jb(jb_fp_t jb);

private:
	/* Montgomery multiplication. */
	void mont_mult(mpz_t &result, mpz_t op1, mpz_t op2);

	/* Convert into Montgomery form. */
	void to_mont(mpz_t &in);

	/* Convert from Montgomery form. */
	void from_mont(mpz_t &in);

	/* Point addition in affine coordinates. Coordinates are in normal form. */
	af_fp_t pt_add(af_fp_t p, af_fp_t q);

	/* Point doubling in affine coordinates. Coordinates are in normal form. */
	af_fp_t pt_dbl(af_fp_t p);
};

#endif
