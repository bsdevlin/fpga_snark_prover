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

#include "bn128.hpp"

Bn128::af_fp_t Bn128::G1_af;
Bn128::af_fp2_t Bn128::G2_af;

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
	
	gmp_printf("Montgomery FACTOR is 0x%Zx\n", factor);
	gmp_printf("Montgomery MASK is 0x%Zx\n", mask);
	gmp_printf("Montgomery CONVERTED_ONE is 0x%Zx\n", converted_one);
	gmp_printf("Montgomery RECIPROCAL is 0x%Zx\n", reciprocal);
	gmp_printf("Montgomery RECIPROCAL_SQ is 0x%Zx\n", reciprocal_sq);
}

Bn128::af_fp_t Bn128::pt_dbl(af_fp_t p) {
	af_fp_t result;
	mpz_t tmp;
	mpz_init(result.x);
	mpz_init(result.y);
	mpz_init(tmp);

	// Check for zero;
        if (mpz_cmp_ui(p.x, 0) == 0 && mpz_cmp_ui(p.y, 0) == 0) {
		return p;
	}

	mpz_mul_ui(tmp, p.y, 2);
	mpz_invert(tmp, tmp, modulus);
	mpz_mul_ui(tmp, tmp, 3);
	mpz_mul(tmp, tmp, p.x);
	mpz_mul(tmp, tmp, p.x);

	mpz_mul(result.x, tmp, tmp);
	mpz_sub(result.x, result.x, p.x);
	mpz_sub(result.x, result.x, p.x);

	mpz_sub(result.y, p.x, result.x);
	mpz_mul(result.y, result.y, tmp);
	mpz_sub(result.y, result.y, p.y);

	mpz_mod(result.x, result.x, modulus);
	mpz_mod(result.y, result.y, modulus);

	return result;
}

Bn128::af_fp2_t Bn128::pt_dbl(af_fp2_t p) {
	af_fp2_t result;
	mpz_t tmp;
	mpz_init(result.x);
	mpz_init(result.y);
	mpz_init(tmp);

	// Check for zero;
        if (mpz_cmp_ui(p.x, 0) == 0 && mpz_cmp_ui(p.y, 0) == 0) {
		return p;
	}

	mpz_mul_ui(tmp, p.y, 2);
	mpz_invert(tmp, tmp, modulus);
	mpz_mul_ui(tmp, tmp, 3);
	mpz_mul(tmp, tmp, p.x);
	mpz_mul(tmp, tmp, p.x);

	mpz_mul(result.x, tmp, tmp);
	mpz_sub(result.x, result.x, p.x);
	mpz_sub(result.x, result.x, p.x);

	mpz_sub(result.y, p.x, result.x);
	mpz_mul(result.y, result.y, tmp);
	mpz_sub(result.y, result.y, p.y);

	mpz_mod(result.x, result.x, modulus);
	mpz_mod(result.y, result.y, modulus);

	return result;
}

Bn128::af_fp_t Bn128::pt_add(af_fp_t p, af_fp_t q) {
	af_fp_t result;
	mpz_t l, tmp;
	mpz_init(result.x);
	mpz_init(result.y);
	mpz_init(l);
	mpz_init(tmp);

	// Check for corner cases;
	if (mpz_cmp_ui(p.x, 0) == 0 && mpz_cmp_ui(p.y, 0) == 0) {
		return q;
	} else if (mpz_cmp_ui(q.x, 0) == 0 && mpz_cmp_ui(q.y, 0) == 0) {
		return p;
	} else if (mpz_cmp(p.x, q.x) == 0 && mpz_cmp(p.y, q.y) == 0) {
		return pt_dbl(p);
	}

	mpz_sub(l, q.x, p.x); 

	mpz_invert(l, l, modulus); 
	mpz_sub(tmp, q.y, p.y); 
	mpz_mul(l, l, tmp); 

	mpz_mul(result.x, l, l);
	mpz_sub(result.x, result.x, p.x);
	mpz_sub(result.x, result.x, q.x);

	mpz_sub(result.y, p.x, result.x);
	mpz_mul(result.y, result.y, l);
	mpz_sub(result.y, result.y, p.y);

	mpz_mod(result.x, result.x, modulus);
	mpz_mod(result.y, result.y, modulus);
	return result;
}

Bn128::af_fp_t Bn128::pt_mul(af_fp_t p, mpz_t s) {
	mpz_t s_, and_;
	af_fp_t result;
	mpz_init(and_);
	mpz_init_set_ui(s_, 1);
	mpz_init_set_ui(result.x, 0);
	mpz_init_set_ui(result.y, 0);

	while (mpz_cmp(s_, s) <= 0) {
		mpz_and(and_, s_, s);	
		if (mpz_cmp_ui(and_, 0) != 0) {
			result = pt_add(result, p);
		}
		p = pt_dbl(p);
	mpz_mul_2exp(s_, s_, 1);
	}
	return result;
}

Bn128::af_fp_t Bn128::multi_exp(std::vector<std::pair<Bn128::af_fp_t, mpz_t>> p_s) {
	af_fp_t result, result_;
	mpz_init_set_ui(result.x, 0);
	mpz_init_set_ui(result.y, 0);

	for (size_t i = 0; i < p_s.size(); i++) {
		result_ = pt_mul(p_s[i].first, p_s[i].second);
		result = pt_add(result, result_);
	}

	return result;
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

	mpz_mod(result, result, modulus);
}

void Bn128::to_mont(mpz_t &in) {
	mpz_t result;
	mpz_init(result);
	mont_mult(result, in, reciprocal_sq);
	mpz_set(in, result);
}

void Bn128::from_mont(mpz_t &in) {
	mpz_t tmp, result;
	mpz_init(result);
	mpz_init_set_ui(tmp, 1);
	mont_mult(result, in, tmp);
	mpz_set(in, result);
}

Bn128::jb_fp_t Bn128::to_mont_jb(af_fp_t af) {
	jb_fp_t result;
	mpz_init_set (result.x, af.x);
	mpz_init_set (result.y, af.y);
	to_mont(result.x);
	to_mont(result.y);
	mpz_init_set (result.z, converted_one);
	return result;
}

Bn128::af_fp_t Bn128::to_mont_af(af_fp_t af) {
	af_fp_t result;
	mpz_init_set (result.x, af.x);
	mpz_init_set (result.y, af.y);
	to_mont(result.x);
	to_mont(result.y);
	return result;
}

Bn128::af_fp_t Bn128::mont_jb_to_af(jb_fp_t jb) {
	mpz_t tmp1, tmp2;
	af_fp_t result;
	jb_fp_t jb_;
	int error;

	mpz_init_set(jb_.x, jb.x);
	mpz_init_set(jb_.y, jb.y);
	mpz_init_set(jb_.z, jb.z);

	from_mont(jb_.x);
	from_mont(jb_.y);
	from_mont(jb_.z);

	mpz_init_set_ui(result.x, 0);
	mpz_init_set_ui(result.y, 0);
	mpz_init(tmp1);
	mpz_init(tmp2);

	mpz_mul(tmp1, jb_.z, jb_.z);
	mpz_mul(tmp2, tmp1, jb_.z);
	error = (mpz_invert(tmp1, tmp1, modulus) == 0);
	error |= (mpz_invert(tmp2, tmp2, modulus) == 0);

	if (error) {
		gmp_printf("ERROR while calculating inverse in jb_to_af()\n");
		return result;
	}

	mpz_mul(result.x, jb_.x, tmp1);
	mpz_mul(result.y, jb_.y, tmp2);

	mpz_mod(result.x, result.x, modulus);
	mpz_mod(result.y, result.y, modulus);

	return result;
}

void Bn128::fe_export(void* data, mpz_t fe) {
	mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, fe);
}

void Bn128::af_export(void* data, af_fp_t af) {
	mpz_export(data, NULL, -1, BN128_BITS/8, -1, 0, af.x);
	mpz_export((void*)((char*)data + BN128_BITS/8), NULL, -1, BN128_BITS/8, -1, 0, af.y);
}

void Bn128::jb_import(jb_fp_t &jb, void* data) {
	mpz_import(jb.x, 1, -1, BN128_BITS/8, -1, 0, data);
	mpz_import(jb.y, 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + BN128_BITS/8));
	mpz_import(jb.z, 1, -1, BN128_BITS/8, -1, 0, (void*)((uint8_t*)data + 2*BN128_BITS/8));
}

void Bn128::print_af(af_fp_t af) {
	gmp_printf("af point (x=0x%Zx, y=0x%Zx)\n", af.x, af.y);
}

void Bn128::print_jb(jb_fp_t jb) {
	gmp_printf("jb point (x=0x%Zx, y=0x%Zx, z=0x%Zx)\n", jb.x, jb.y, jb.z);
}
