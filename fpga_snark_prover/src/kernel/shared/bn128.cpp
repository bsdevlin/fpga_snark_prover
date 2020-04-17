 /*
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

#include <bn128.h>

Bn128::Bn128 () {
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

	mpz_init_set_str(G1_af.x, G1_X, 10);
	mpz_init_set_str(G1_af.y, G1_Y, 10);

	af_to_mont(G1_af, G1_mont_af);

	mpz_init_ui(const_3, 3);
	to_mont(const_3);

	mpz_init_ui(const_2, 2);
	to_mont(const_2);

	gmp_printf("Montgomery FACTOR is 0x%Zx\n", factor);
	gmp_printf("Montgomery MASK is 0x%Zx\n", mask);
	gmp_printf("Montgomery CONVERTED_ONE is 0x%Zx\n", converted_one);
	gmp_printf("Montgomery RECIPROCAL is 0x%Zx\n", reciprocal);
	gmp_printf("Montgomery RECIPROCAL_SQ is 0x%Zx\n", reciprocal_sq);
}

void Bn128::mul(fe_t &result, fe_t a, fe_t b) {
	mont_mult((mpz_t)result, (mpz_t)a, (mpz_t)b);
}

void Bn128::add(fe_t &result, fe_t a, fe_t b) {
	mpz_add(result, a, b);
	mpz_mod(result, result, modulus);
}

void Bn128::sub(fe_t &result, fe_t a, fe_t b) {
	mpz_sub(result, a, b);
	mpz_mod(result, result, modulus);
}

void Bn128::pt_dbl(af_fp_t &result, af_fp_t p) {
	mpz_t tmp;
	mpz_init(result.x);
	mpz_init(result.y);
	mpz_init(tmp);

	// Check for zero;

	mul(tmp, p.y, const_2);
	mpz_invert(tmp, tmp, modulus);
	mul(tmp, tmp, const_3);
	mul(tmp, tmp, p.x);
	mul(tmp, tmp, p.x);

	mul(result.x, tmp, tmp);
	sub(result.x, result.x, p.x);
	sub(result.x, result.x, p.x);

	sub(result.y, p.x, r.x);
	mul(result.y, result.y, tmp);
	sub(result.y, result.y, p.y);

	mpz_mod(result.x, result.x, modulus);
	mpz_mod(result.y, result.y, modulus);
}

void Bn128::pt_add(af_fp_t &result, af_fp_t p, af_fp_t q) {
	mpz_t tmp0, tmp1;
	mpz_init(result.x);
	mpz_init(result.y);
	mpz_init(tmp0);
	mpz_init(tmp1);

	// Check for zero;

	if (mpz_cmp(p.x, q.x) == 0 && mpz_cmp(p.y, q.y) == 0) {
		return pt_dbl(result, a);
	}

	sub(tmp0, q.x, p.x);
	mpz_invert(tmp0, tmp0, modulus);
	sub(tmp1, q.y, p.y);
	mul(tmp0, tmp0, tmp1);

	mul(result.x, tmp0, tmp0);
	sub(result.x, result.x, p.x);

	sub(result.y, p.x, result.x);
	mul(result.y, result.y, tmp0);
	sub(result.y, result.y, p.y);
}

af_fp_t result Bn128::pt_mul(af_fp_t p, int n) {
	int i;
	af_fp_t r;
	mpz_init_set_ui(r.x, 0);
	mpz_init_set_ui(r.y, 0);

	for (i = 1; i <= n; i <<= 1) {
		if (i & n) r = pt_add(r, p);
		p = pt_dbl(p);
	}
	return r;
}

void Bn128::mont_mult(mpz_t &result, mpz_t op1, mpz_t op2) {
	mpz_t tmp;
	mpz_init(tmp);
	mpz_mul(tmp, op1, op2);

	mpz_and(result, tmp, mask);
	mpz_mul(result, result, factor);
	mpz_and(result, result, mask);

	mpz_mul(result, result, modulus);
	mpz_add(result, result, tmp);
	mpz_tdiv_q_2exp(result, result, BN128_BITS);

	if (mpz_cmp(result, modulus) > 0) {
		mpz_sub(result, result, modulus);
	}
}

void Bn128::to_mont(mpz_t &result) {
	mont_mult(result, result, reciprocal_sq);
}

void Bn128::from_mont(mpz_t &result) {
	mpz_t tmp;
	mpz_init(tmp);
	mpz_set_ui(tmp, 1);
	mont_mult(result, result, tmp);
}

void Bn128::af_to_jb(af_fp_t af, jb_fp_t &jb) {
	mpz_init_set (jb.x, af.x);
	mpz_init_set (jb.y, af.y);
	mpz_init_set_ui (jb.z, 1);
}

void Bn128::af_to_mont(af_fp_t af, af_fp_t &af_mont) {
	mpz_init_set (af_mont.x, af.x);
	to_mont(af_mont.x);
	mpz_init_set (af_mont.y, af.y);
	to_mont(af_mont.y);
}

void Bn128::af_from_mont(af_fp_t af_mont, af_fp_t &af) {
	mpz_init_set (af.x, af_mont.x);
	from_mont(af.x);
	mpz_init_set (af.y, af_mont.y);
	from_mont(af.y);
}

int Bn128::jb_to_af(jb_fp_t jb, af_fp_t &af) {
	mpz_t tmp1, tmp2;
	int error;

	mpz_init(af.x);
	mpz_init(af.y);
	mpz_init(tmp);
	mont_mult(tmp1, jb.z, jb.z);
	mont_mult(tmp2, tmp1, jb.z);
	error = (mpz_invert(tmp1, tmp1, modulus) == 0);
	error |= (mpz_invert(tmp2, tmp2, modulus) == 0);

	if (error) {
		gmp_printf("ERROR while calculating inverse in jb_to_af()\n");
		return -1;
	}

	mont_mult(af.x, jb.x, tmp1);
	mont_mult(af.y, jb.y, tmp2);
	return 0;
}

void Bn128::af_export(void* data, af_fp_t af) {
	mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, af.x);
	mpz_export((void*)((uint8_t*)data + BN128_BITS/8), NULL, -1, BN128_BITS/8, -1, 0, af.y);
}

void Bn128::jb_import(jb_fp_t &jb, void* data) {
	mpz_import(jb.x, 1, -1, BN128_BITS/8, -1, 0, data);
	mpz_import(jb.y, 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + BN128_BITS/8));
	mpz_import(jb.z, 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + 2*BN128_BITS/8));
}

void Bn128::print_af(af_fp_t af) {
	gmp_printf("point (x=0x%Zx, y=0x%Zx)\n", af.x, af.y);
}

void Bn128::print_jb(jb_fp_t jb) {
	gmp_printf("point (x=0x%Zx, y=0x%Zx, z=0x%Zx)\n", jb.x, jb.y, jb.z);
}
