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

#define G2_X0 "11559732032986387107991004021392285783925812861821192530917403151452391805634"
#define G2_X1 "10857046999023057135944570762232829481370756359578518086990519993285655852781"
#define G2_Y0 "4082367875863433681332203403145435568316851327593401208105741076214120093531"
#define G2_Y1 "8495653923123431417604973247489272438418190587263600148770280649306958101930"

class Bn128 {
public:

	struct fe_t {
		mpz_t c0;

		bool operator==(const fe_t& a) const {
			return (mpz_cmp(c0, a.c0) == 0);
		}
		fe_t operator*(const fe_t& a) const {
			fe_t res;
			mpz_init(res);
			mpz_mul(res, c0, a);
			mpz_mod(res, res, modulus);
			return res;
		}
		fe_t operator+(const fe_t& a) const {
			fe_t res;
			mpz_init(res);
			mpz_add(res, c0, a);
			mpz_mod(res, res, modulus);
			return res;
		}
		fe_t operator-(const fe_t& a) const {
			fe_t res;
			mpz_init(res);
			mpz_sub(res, c0, a);
			mpz_mod(res, res, modulus);
			return res;
		}
		fe_t operator/(const fe_t a) cont {
			fe_t res;
			mpz_init(res);
			mpz_invert(res, a.c0, modulus);
			return c0 * res;
		}
	};

	struct jb_fp_t {
		fe_t x;
		fe_t y;
		fe_t z;

		bool operator==(const jb_fp_t& a) const {
			return (x == a.x &&
					y == a.y &&
					z == a.z);
		}
	};

	struct af_fp_t {
		fe_t x;
		fe_t y;

		bool operator==(const af_fp_t& a) const {
			return (x == a.x &&
					y == a.y);
		}
	};

	struct fe2_t {
		fe_t c0;
		fe_t c1;

		bool operator==(const fe_t& a) const {
			return (c0 == a.c0 &&
					c1 == a.c1);
		}
		fe2_t operator*(const fe_t& a) const {
			fe2_t res;
			fe_t t0, t1, t2, t3;
			mpz_init_set(t0, c0 * a.c0);
			mpz_init_set(t1, c0 * a.c1);
			mpz_init_set(t2, c1 * a.c0);
			mpz_init_set(t3, c1 * a.c1);
			mpz_init_set(res.c0, t0 - t3);
			mpz_init_set(res.c1, t1 + t2);
			return res;
		}
		fe2_t operator+(const fe_t& a) const {
			fe2_t res;
			mpz_init_set(res.c0, c0 + a.c0);
			mpz_init_set(res.c1, c1 + a.c1);
			return res;
		}
		fe2_t operator-(const fe_t& a) const {
			fe2_t res;
			mpz_init_set(res.c0, c0 - a.c0);
			mpz_init_set(res.c1, c1 - a.c1);
			return res;
		}
	};

	struct jb_fp2_t {
		fe2_t x;
		fe2_t y;
		fe2_t z;

		bool operator==(const jb_fp2_t& a) const {
			return (x == a.x &&
					y == a.y &&
					z == a.z);
		}
	};

	struct af_fp2_t {
		fe2_t x;
		fe2_t y;

		bool operator==(const af_fp2_t& a) const {
			return (x == a.x &&
					y == a.y);
		}
	};



	static af_fp_t G1_af;
	static af_fp2_t G2_af;

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

	/* Naive implementation of G1 and G2 multi exponentiation of vector of point, scalar pairs */
	af_fp_t multi_exp(std::vector<std::pair<Bn128::af_fp_t, mpz_t>> p_s);
	//af_fp2_t multi_exp(std::vector<std::pair<Bn128::af_fp2_t, mpz_t>> p_s);

	/* Point multiplication p by scalar s. */
	af_fp_t pt_mul(af_fp_t p, mpz_t s);
	//af_fp2_t pt_mul(af_fp2_t p, mpz_t s);

	/* Convert a af_fp_t in normal form to jb_fp_t in Montgomery form. */
	jb_fp_t to_mont_jb(af_fp_t af);
	//jb_fp2_t to_mont_jb(af_fp2_t af);

	/* Do an inversion and convert from jb in Montgomery form back into af in normal form coordinates.
	   Returns a 0 point if there was an error an no inverse exists. */
	af_fp_t mont_jb_to_af(jb_fp_t jb);
	//af_fp2_t mont_jb_to_af(jb_fp2_t jb);
	
	/* Converts an af point into montgomery form, used for loading input into FPGA as internally we convert into jb. */
	af_fp_t to_mont_af(af_fp_t af);
	//af_fp2_t to_mont_af(af_fp2_t af);

	/* Takes a void pointer and exports the point data in a af_fp_t to it */
	void af_export(void* data, af_fp_t af);
	void af_export(void* data, af_fp2_t af);

	/* Takes a void pointer and exports the scalar data in a mpz_t to it */
	void fe_export(void* data, mpz_t fe);
	
	/* Takes a jb_fp_t and fills it with jb point data from a void pointer. */
	void jb_import(jb_fp_t &jb, void* data);
	//void jb_import(jb_fp2_t &jb, void* data);

	/* Print a af_fp_t point's coordinates. */
	void print_af(af_fp_t af);
	//void print_af(af_fp2_t af);
	
	/* Print a jb_fp_t in Montgomery form point's coordinates. */
	void print_jb(jb_fp_t jb);
	//void print_jb(jb_fp2_t jb);

private:
	/* Montgomery multiplication. */
	void mont_mult(mpz_t &result, mpz_t op1, mpz_t op2);

	/* Convert into Montgomery form. */
	void to_mont(mpz_t &in);

	/* Convert from Montgomery form. */
	void from_mont(mpz_t &in);

	/* Point addition in affine coordinates. Coordinates are in normal form. */
	af_fp_t pt_add(af_fp_t p, af_fp_t q);
	//af_fp2_t pt_add(af_fp2_t p, af_fp2_t q);

	/* Point doubling in affine coordinates. Coordinates are in normal form. */
	af_fp_t pt_dbl(af_fp_t p);
	//af_fp2_t pt_dbl(af_fp2_t p);
};

#endif
