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
#include <gmpxx.h>
#include <stdint.h>
#include <string>
#include <iostream>

#define BN128_BITS 256
#define BN128_MODULUS "21888242871839275222246405745257275088696311157297823662689037894645226208583"

class Bn128 {
public:
	template<int T>
	struct f_t {
		mpz_t c [T];
		f_t () {
			for (int i = 0; i < T; i++)
				mpz_init(c[i]);
		}
		f_t (const mpz_t a) {
			for (int i = 0; i < T; i++)
				mpz_init_set(c[i], a);
		}
		f_t (const int a) {
			for (int i = 0; i < T; i++)
				mpz_init_set_ui(c[i], a);
		}
		f_t (std::string a[T]) {
			for (int i = 0; i < T; i++) 
				mpz_init_set_str(c[i], a[i].c_str(), 10);
		}
		bool operator==(const int a) const {
			bool equal = true;
			for (int i = 0; i < T; i++) 
				equal &= (mpz_cmp_ui(c[i], a) == 0);
			return equal;
		}
		bool operator==(const f_t<T> a) const {
			bool equal = true;
			for (int i = 0; i < T; i++) 
				equal &= (mpz_cmp(c[i], a.c[i]) == 0);
			return equal;
		}
		f_t operator*(const int a) const {
			f_t c_;
			for (int i = 0; i < T; i++) {
				mpz_mul_ui(c_.c[i], c[i], a);
				mpz_mod(c_.c[i], c_.c[i], modulus);
			}
			return c_;
		}
		f_t operator*(const f_t<1> a) const {
			f_t c0_;
			mpz_mul(c0_.c[0], c[0], a.c[0]);
			mpz_mod(c0_.c[0], c0_.c[0], modulus);
			return c0_;
		}
		f_t operator*(const f_t<2> a) const {
			f_t<2> res;
			f_t<1> t0, t1, t2, t3;
			mpz_mul(t0.c[0], a.c[0], c[0]);
			mpz_mul(t1.c[0], a.c[1], c[0]);
			mpz_mul(t2.c[0], a.c[0], c[1]);
			mpz_mul(t3.c[0], a.c[1], c[1]);
			mpz_sub(res.c[0], t0.c[0], t3.c[0]);
			mpz_add(res.c[1], t1.c[0], t2.c[0]);
			mpz_mod(res.c[0], res.c[0], modulus);
			mpz_mod(res.c[1], res.c[1], modulus);
			return res;
		}
		f_t operator+(const f_t a) const {
			f_t c_;
			for (int i = 0; i < T; i++) {
				mpz_add(c_.c[i], a.c[i], c[i]);
				mpz_mod(c_.c[i], c_.c[i], modulus);
			}
			return c_;
		}
		f_t operator-(const f_t a) const {
			f_t c_;
			for (int i = 0; i < T; i++) {
				mpz_sub(c_.c[i], c[i], a.c[i]);
				mpz_mod(c_.c[i], c_.c[i], modulus);
			}
			return c_;
		}
		f_t operator/(const f_t<1> a) const {
			f_t c_;
			mpz_invert(c_.c[0], a.c[0], modulus);
			mpz_mul(c_.c[0], c[0], c_.c[0]);
			mpz_mod(c_.c[0], c_.c[0], modulus);
			return c_; 
		}
		f_t operator/(const f_t<2> a) const {
			f_t<2> res;
			f_t<1> t0, t1, f;
			mpz_mul(t0.c[0], a.c[0], a.c[0]);
			mpz_mul(t1.c[0], a.c[1], a.c[1]);
			f = f_t<1>(1) / (t0 + t1);

			mpz_mul(res.c[0], a.c[0], f.c[0]);
			mpz_sub(res.c[1], modulus, a.c[1]);
			mpz_mul(res.c[1], res.c[1], f.c[0]);
			
			res = res * (*this);	
			return res; 
		}
		void print() {
			for (int i = 0; i < T; i++)
				std::cout << "c" << i << ":0x" << std::hex << c[i] << ",";
		}


	};

	template<typename T>
	struct jb_p_t {
		T x;
		T y;
		T z;
		void print() {
			std::cout << "(x=";
			x.print();
			std::cout << " y=";
			y.print();
			std::cout << " z=";
			z.print();
			std::cout << ")\n";
		}
	};

	template<typename T>
	struct af_p_t {
		T x;
		T y;
		af_p_t<T> () {}

		af_p_t<T> (T a, T b) {
			x = a;
			y = b;
		}
    		bool operator==(const af_p_t a) const {
        		return ((x == a.x) && (y == a.y));
    		}
    		bool operator==(const int a) const {
        		return ((x == a) && (y == a));
    		}
		af_p_t<T> operator=(const int a) {
			x = a;
			y = a;
			return *this;
		}
		af_p_t<T> operator+(const af_p_t a) const {
			af_p_t<T> p, q, res;
			T L;
			p = a;
			q = *this;
			if (p == 0) {
				return *this;
			} else if (*this == 0) {
				return p;
			} else if (*this == p) {
				L = ((q.x * q.x) * 3) / (q.y * 2);
			} else {
				L = (q.y - p.y) / (q.x - p.x);
			}
			res.x = (L * L) - p.x - q.x;			
			res.y = L * (p.x - res.x) - p.y;
			return res;
		}
		af_p_t<T> operator*(const mpz_t a) const {
			mp_bitcnt_t i;
			af_p_t<T> res, p;
			p = *this;
			res = 0;
			i = 0;
			// Point multiplication
			while (i < BN128_BITS) {
				if(mpz_tstbit(a, i)) {
					res = res + p;
				}
				p = p + p;
				i++;
			}
			return res;
		}
		void print() {
			std::cout << "(x=";
			x.print();
			std::cout << " y=";
			y.print();
			std::cout << ")\n";
		}
	};

	static af_p_t<f_t<1>> G1_af;
	static af_p_t<f_t<2>> G2_af;
	static mpz_t modulus;
	static mpz_t reciprocal_sq;
	static mpz_t reducer;
	static mpz_t mask;
	static mpz_t factor;
	static mpz_t converted_one;
	static mpz_t reciprocal;

	/* The constructor sets up the montgomery values and generator points. */
	Bn128() {
		mpz_init_set_str(modulus, BN128_MODULUS, 10);

		mpz_init_set_ui(reducer, 1);
		mpz_mul_2exp(reducer, reducer, BN128_BITS);

		mpz_init(mask);
		mpz_sub_ui(mask, reducer, 1);

		mpz_init(reciprocal);
		mpz_mod(reciprocal, reducer, modulus);
		mpz_invert(reciprocal, reciprocal, modulus);

		mpz_init(reciprocal_sq);
		mpz_mul(reciprocal_sq, reducer, reducer);
		mpz_mod(reciprocal_sq, reciprocal_sq, modulus);

		mpz_init(factor);
		mpz_mul(factor, reducer, reciprocal);
		mpz_sub_ui(factor, factor, 1);
		mpz_cdiv_q(factor, factor, modulus);

		mpz_init(converted_one);
		mpz_mod(converted_one, reducer, modulus);

		mpz_init_set_str(G1_af.x.c[0], "1", 10);
		mpz_init_set_str(G1_af.y.c[0], "2", 10);

		mpz_init_set_str(G2_af.x.c[0], "10857046999023057135944570762232829481370756359578518086990519993285655852781", 10);
		mpz_init_set_str(G2_af.x.c[1], "11559732032986387107991004021392285783925812861821192530917403151452391805634", 10);
		mpz_init_set_str(G2_af.y.c[0], "8495653923123431417604973247489272438418190587263600148770280649306958101930", 10);
		mpz_init_set_str(G2_af.y.c[1], "4082367875863433681332203403145435568316851327593401208105741076214120093531", 10);
	}

	/* Converts an af point into montgomery form, used for loading input into FPGA. We internally convert into jb. */
	template <int N>
	static af_p_t<f_t<N>> to_mont(af_p_t<f_t<N>> af) {
		af_p_t<f_t<N>> res;
		res.x = mont_mult(af.x, reciprocal_sq);
		res.y = mont_mult(af.y, reciprocal_sq);
		return res;
	}

	/* Takes a void pointer and exports the point data in a af_fp_t to it */
	template <int N>
	static void af_export(void* data, af_p_t<f_t<N>> af) {
		for (int i = 0; i < N; i++) {
			mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, af.x.c[i]);
			mpz_export((void*)((char*)data + BN128_BITS/8), NULL, -1, BN128_BITS/8, -1, 0, af.y.c[i]);
		}
	};

	/* Takes a jb_fp_t and fills it with jb point data from a void pointer. */
	template <int N>
	static void jb_import(jb_p_t<f_t<N>> &jb, void* data) {
		for (int i = 0; i < N; i++) {
			mpz_import(jb.x.c[i], 1, -1, BN128_BITS/8, -1, 0, data);
			mpz_import(jb.y.c[i], 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + BN128_BITS/8));
			mpz_import(jb.z.c[i], 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + 2*BN128_BITS/8));
		}
	};

	/* Takes a void pointer and exports the scalar data in a mpz_t to it */
	static void fe_export(void* data, mpz_t fe) {
		mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, fe);
	}

	/* Do an inversion and convert from jb in Montgomery form back into af in normal form coordinates.
	   Returns a 0 point if there was an error an no inverse exists. */
	template <typename T>
	static af_p_t<T> mont_jb_to_af(jb_p_t<T> jb) {
		jb_p_t<T> jb_tmp;
		af_p_t<T> af;
		T t;
		mpz_t one;
		mpz_init_set_ui (one, 1);
		jb_tmp.x = mont_mult(jb.x, one);
		jb_tmp.y = mont_mult(jb.y, one);
		t = mont_mult(jb.z, one);
		jb_tmp.z = t * t;
		af.x = jb_tmp.x / jb_tmp.z;
		jb_tmp.z = jb_tmp.z * t;
		jb_tmp.z = T (1) / jb_tmp.z;
		af.y = jb_tmp.y * jb_tmp.z;
		return af;
	}

	/* Montgomery multiplication for a f_t by a mpz_t */
	template <int N>
	static f_t<N> mont_mult(f_t<N> op1, mpz_t op2) {
		f_t<N> tmp;
		f_t<N> res;
		for (int i = 0; i < N; i++) {
			mpz_mul(tmp.c[i], op1.c[i], op2);
			mpz_and(res.c[i], tmp.c[i], mask);
			mpz_mul(res.c[i], res.c[i], factor);
			mpz_and(res.c[i], res.c[i], mask);

			mpz_mul(res.c[i], res.c[i], modulus);
			mpz_add(res.c[i], res.c[i], tmp.c[i]);
			mpz_tdiv_q_2exp(res.c[i], res.c[i], BN128_BITS);
			mpz_mod(res.c[i], res.c[i], modulus);
		}
		return res;
	}
};

mpz_t Bn128::modulus;
mpz_t Bn128::reciprocal_sq;
mpz_t Bn128::reducer;
mpz_t Bn128::mask;
mpz_t Bn128::factor;
mpz_t Bn128::converted_one;
mpz_t Bn128::reciprocal;

Bn128::af_p_t<Bn128::f_t<1>> Bn128::G1_af;
Bn128::af_p_t<Bn128::f_t<2>> Bn128::G2_af;

#endif
