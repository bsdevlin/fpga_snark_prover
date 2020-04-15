#ifndef BN128_H
#define BN128_H

#include <gmp.h>

#define DAT_BITS 256
#define BN128_MODULUS "21888242871839275222246405745257275088696311157297823662689037894645226208583"
#define G1_X "1"
#define G1_Y "2"

class Bn128 {
protected:
	mpz_t reducer;
	mpz_t mask;
	mpz_t factor;
	mpz_t converted_one;
	mpz_t reciprocal_sq;
	mpz_t reciprocal;
	mpz_t modulus;
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

	void mont_init() {

		mpz_init(modulus);
		mpz_set_str (modulus, BN128_MODULUS, 10);

		mpz_init(reducer);
		mpz_set_ui(reducer, 1);
		bn_shl(reducer, DAT_BITS);

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

		gmp_printf("Montgomery FACTOR is 0x%Zx\n", factor);
		gmp_printf("Montgomery MASK is 0x%Zx\n", mask);
		gmp_printf("Montgomery CONVERTED_ONE is 0x%Zx\n", converted_one);
		gmp_printf("Montgomery RECIPROCAL is 0x%Zx\n", reciprocal);
		gmp_printf("Montgomery RECIPROCAL_SQ is 0x%Zx\n", reciprocal_sq);

	}

	// Montgomery multiplication
	void mont_mult(mpz_t result, mpz_t op1, mpz_t op2) {
		mpz_t tmp;
		mpz_init(tmp);
		mpz_mul(tmp, op1, op2);

		mpz_and(result, tmp, mask);
		mpz_mul(result, result, factor);
		mpz_and(result, result, mask);

		mpz_mul(result, result, modulus);
		mpz_add(result, result, tmp);
		bn_shr(result, DAT_BITS);

		if (mpz_cmp(result, modulus) > 0) {
			mpz_sub(result, result, modulus);
		}
	}

	// Convert into Montgomery form
	void to_mont(mpz_t result) {
		mont_mult(result, result, reciprocal_sq);
	}

	// Convert from Montgomery form
	void from_mont(mpz_t result) {
		mpz_t tmp;
		mpz_init(tmp);
		mpz_set_ui(tmp, 1);
		mont_mult(result, result, tmp);
	}

	void af_to_jb(af_fp_t af, jb_fp_t jb) {
		mpz_init_set (jb.x, af.x);
		mpz_init_set (jb.y, af.y);
		mpz_init_set_ui (jb.z, 1);
	}


};

#endif
