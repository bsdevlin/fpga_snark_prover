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

	gmp_printf("Montgomery FACTOR is 0x%Zx\n", factor);
	gmp_printf("Montgomery MASK is 0x%Zx\n", mask);
	gmp_printf("Montgomery CONVERTED_ONE is 0x%Zx\n", converted_one);
	gmp_printf("Montgomery RECIPROCAL is 0x%Zx\n", reciprocal);
	gmp_printf("Montgomery RECIPROCAL_SQ is 0x%Zx\n", reciprocal_sq);
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

void Bn128::af_export (void* data, af_fp_t af) {
	mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, af.x);
	mpz_export((void*)((uint8_t*)data + BN128_BITS/8), NULL, -1, BN128_BITS/8, -1, 0, af.y);
}

void Bn128::jb_import (jb_fp_t &jb, void* data) {
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
