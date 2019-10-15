/*
  Package for the bn128 curve

  Copyright (C) 2019  Benjamin Devlin and Ethereum Foundation

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

package bn128_pkg;

  localparam [DAT_BITS-1:0] P = 256'd21888242871839275222246405745257275088696311157297823662689037894645226208583;

  typedef logic [255:0] fe_t;
  typedef fe_t [1:0] fe2_t;

  // Jacobian coordinates for Fp and Fp2 elements
  typedef struct packed {
    fe_t z;
    fe_t y;
    fe_t x;
  } jb_point_t;

  typedef struct packed {
    fe2_t z;
    fe2_t y;
    fe2_t x;
  } fp2_jb_point_t;

  // Affine points for Fp and Fp2 elements
  typedef struct packed {
    fe_t y;
    fe_t x;
  } af_point_t;

  typedef struct packed {
    fe2_t y;
    fe2_t x;
  } fp2_af_point_t;

  // Generator points
  fe_t G1X = 'd1;
  fe_t G1Y = 'h2;

  af_point_t G1_AF = '{x:G1X, y:G1Y};
  jb_point_t G1_JB = '{x:G1X, y:G1Y, z:'d1};

  fe2_t G2X = {'d10857046999023057135944570762232829481370756359578518086990519993285655852781, 'd11559732032986387107991004021392285783925812861821192530917403151452391805634};
  fe2_t G2Y = {'d8495653923123431417604973247489272438418190587263600148770280649306958101930, 'd4082367875863433681332203403145435568316851327593401208105741076214120093531};
  fe2_t FE2_ONE = {'d0, 'd1};

  fp2_af_point_t G2_AF = '{x:G2X, y:G2Y};
  fp2_jb_point_t G2_JB = '{x:G2X, y:G2Y, z:FE2_ONE};


endpackage