/*
  This performs point doubling on a prime field Fp using jacobian points.

  Copyright (C) 2019  Benjamin Devlin and Zcash Foundation

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

module ec_fpn_dbl
#(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter type FE_TYPE_ARITH,      // This is the bit width used in arithmetic blocks - should be a power of 2 
  // If we use Montgomery form we need to override these
  parameter FE_TYPE CONST_3 = 3,
  parameter FE_TYPE CONST_4 = 4,
  parameter FE_TYPE CONST_8 = 8
)(
  input i_clk, i_rst,
  // Input point
  input FP_TYPE i_p,
  input logic   i_val,
  output logic  o_rdy,
  // Output point
  output FP_TYPE o_p,
  input logic    i_rdy,
  output logic   o_val,
  output logic   o_err,
  // Interface to multiplier (mod P)
  if_axi_stream.source o_mul_if,
  if_axi_stream.sink   i_mul_if,
  // Interface to adder (mod P)
  if_axi_stream.source o_add_if,
  if_axi_stream.sink   i_add_if,
  // Interface to subtractor (mod P)
  if_axi_stream.source o_sub_if,
  if_axi_stream.sink   i_sub_if
);

localparam CHK_INPUT = 0;
/*
 * These are the equations that need to be computed, they are issued as variables
 * become valid. We have a bitmask to track what equation results are valid which
 * will trigger other equations. [] show what equations must be valid before this starts.
 *
 * 0.    A = (i_p.y)^2 mod p
 * 1.    B = (i_p.x)*A mod p [eq0]
 * 2.    B = 4*B mod p [eq1]
 * 3.    C = A^2 mod p [eq0]
 * 4.    C = C*8 mod p [eq3]
 * 5.    D = (i_p.x)^2 mod p
 * 6.    D = 3*D mod p [eq5]
 * 7.   (o_p.x) = D^2 mod p[eq6]
 * 8.    E = 2*B mod p [eq2]
 * 9.   (o_p.x) = o_p.x - E mod p [eq8, eq7]
 * 10   (o_p.y) =  B - o_p.x mod p [eq9, eq2]
 * 11.   (o_p.y) = D*(o_p.y) [eq10, eq6]
 * 12.   (o_p.y) = (o_p.y) - C mod p [eq11, eq4]
 * 13.   (o_p.z) = 2*(i_p.y) mod p
 * 14.   (o_p.z) = o_p.y * i_p.z mod p [eq14]
 */
logic [14:0] eq_val, eq_wait;

localparam ARITH_BITS = $bits(FE_TYPE_ARITH);
localparam DIV = $bits(FE_TYPE)/ARITH_BITS;
localparam DIV_LOG2 = DIV == 1 ? 1 : $clog2(DIV);

logic [DIV_LOG2-1:0] add_o_cnt, sub_o_cnt, add_i_cnt, sub_i_cnt, mul_i_cnt, mul_o_cnt;
logic mul_en, add_en, sub_en;
logic [5:0] nxt_mul, nxt_add, nxt_sub;

// Temporary variables
FE_TYPE A, B, C, D, E;
FP_TYPE i_p_l;


enum {IDLE, START, FINISHED} state;
always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_val <= 0;
    o_rdy <= 0;
    o_p <= 0;
    o_mul_if.copy_if(0, 0, 1, 1, 0, 0, 0);
    o_add_if.copy_if(0, 0, 1, 1, 0, 0, 0);
    o_sub_if.copy_if(0, 0, 1, 1, 0, 0, 0);
    i_mul_if.rdy <= 0;
    i_add_if.rdy <= 0;
    i_sub_if.rdy <= 0;
    eq_val <= 0;
    state <= IDLE;
    eq_wait <= 0;
    i_p_l <= 0;
    o_err <= 0;
    A <= 0;
    B <= 0;
    C <= 0;
    D <= 0;
    E <= 0;
    {add_o_cnt, sub_o_cnt, add_i_cnt, sub_i_cnt, mul_i_cnt, mul_o_cnt} <= 0;
    {mul_en, add_en, sub_en} <= 0;
    {nxt_mul, nxt_add, nxt_sub} <= 0;  
  end else begin
    
    i_mul_if.rdy <= 1;
    i_add_if.rdy <= 1;
    i_sub_if.rdy <= 1;

    if (o_mul_if.rdy) o_mul_if.val <= 0;
    if (o_add_if.rdy) o_add_if.val <= 0;
    if (o_sub_if.rdy) o_sub_if.val <= 0;
    if (i_rdy) begin
      o_val <= 0;
      o_err <= 0;
    end

    case(state)
      {IDLE}: begin
        o_rdy <= 1;
        eq_val <= 0;
        eq_wait <= 0;
        o_err <= 0;
        i_p_l <= i_p;
        A <= 0;
        B <= 0;
        C <= 0;
        D <= 0;
        E <= 0;
        {mul_en, add_en, sub_en} <= 0;
        {nxt_mul, nxt_add, nxt_sub} <= 0;        
        o_val <= 0;
        if (i_val && o_rdy) begin
          state <= START;
          o_rdy <= 0;
          if (CHK_INPUT == 1) begin
            if (i_p.z == 0) begin
              o_p <= i_p;
              o_val <= 1;
              state <= FINISHED;
            end
          end
        end
      end
      // Just a big if tree where we issue equations if the required inputs
      // are valid
      {START}: begin
        i_mul_if.rdy <= 1;
        
        if (~sub_en) get_next_sub();
        if (~add_en) get_next_add();
        if (~mul_en) get_next_mul();

        // Check any results from multiplier
        if (i_mul_if.val && i_mul_if.rdy) begin
          mul_i_cnt <= mul_i_cnt + 1;
          if (mul_i_cnt == DIV-1) begin
            eq_val[i_mul_if.ctl[5:0]] <= 1;
            mul_i_cnt <= 0;
          end
          case(i_mul_if.ctl[5:0]) inside
            0: A[mul_i_cnt] <= i_mul_if.dat;
            1: B[mul_i_cnt] <= i_mul_if.dat;
            2: B[mul_i_cnt] <= i_mul_if.dat;
            3: C[mul_i_cnt] <= i_mul_if.dat;
            4: C[mul_i_cnt] <= i_mul_if.dat;
            5: D[mul_i_cnt] <= i_mul_if.dat;
            6: D[mul_i_cnt] <= i_mul_if.dat;
            7: o_p.x[mul_i_cnt] <= i_mul_if.dat;
            11: o_p.y[mul_i_cnt] <= i_mul_if.dat;
            14: o_p.z[mul_i_cnt] <= i_mul_if.dat;
            default: o_err <= 1;
          endcase
        end

        // Check any results from adder
        if (i_add_if.val && i_add_if.rdy) begin
          add_i_cnt <= add_i_cnt + 1;
          if (add_i_cnt == DIV-1) begin
            eq_val[i_add_if.ctl[5:0]] <= 1;
            add_i_cnt <= 0;
          end
          case(i_add_if.ctl[5:0]) inside
            8: E[add_i_cnt] <= i_add_if.dat;
            13: o_p.z[add_i_cnt] <= i_add_if.dat;
            default: o_err <= 1;
          endcase
        end

        // Check any results from subtractor
        if (i_sub_if.val && i_sub_if.rdy) begin
          sub_i_cnt <= sub_i_cnt + 1;
          if (sub_i_cnt == DIV-1) begin
            eq_val[i_sub_if.ctl[5:0]] <= 1;
            sub_i_cnt <= 0;
          end
          case(i_sub_if.ctl[5:0]) inside
            9: o_p.x[sub_i_cnt] <= i_sub_if.dat;
            10: o_p.y[sub_i_cnt] <= i_sub_if.dat;
            12: o_p.y[sub_i_cnt] <= i_sub_if.dat;
            default: o_err <= 1;
          endcase
        end
        
        if (mul_en)
          case (nxt_mul)
            0: multiply(0, i_p_l.y, i_p_l.y);
            1: multiply(1, i_p_l.x, A);
            3: multiply(3, A, A);
            5: multiply(5, i_p_l.x, i_p_l.x);
            6: multiply(6, CONST_3, D);
            7: multiply(7, D, D);
            11: multiply(11, D, o_p.y);
            14: multiply(14, i_p_l.z, o_p.z);
            2: multiply(2, B, CONST_4);
            4: multiply(4, C, CONST_8);
          endcase

        if (sub_en)
          case (nxt_sub)
            9: subtraction(9, o_p.x, E);
            10: subtraction(10, B, o_p.x);
            12: subtraction(12, o_p.y, C);
          endcase

        if (add_en)
          case (nxt_add)
            8: addition(8, B, B);
            13: addition(13, i_p_l.y, i_p_l.y);
          endcase

        if (&eq_val) begin
          state <= FINISHED;
          o_val <= 1;
        end
      end
      {FINISHED}: begin
        if (o_val && i_rdy) begin
          state <= IDLE;
          o_val <= 0;
          o_rdy <= 1;
        end
      end
    endcase

    if (o_err & ~o_val) begin
      o_val <= 1;
      if (o_val && i_rdy) begin
        o_err <= 0;
        state <= IDLE;
      end
    end

  end
end

// Task for subtractions
task subtraction(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_sub_if.val || (o_sub_if.val && o_sub_if.rdy)) begin
    o_sub_if.val <= 1;
    o_sub_if.dat[0 +: ARITH_BITS] <= a[sub_o_cnt];
    o_sub_if.dat[ARITH_BITS +: ARITH_BITS] <= b[sub_o_cnt];
    o_sub_if.ctl[5:0] <= ctl;
    o_sub_if.sop <= sub_o_cnt == 0;
    o_sub_if.eop <= sub_o_cnt == DIV-1;  
    eq_wait[ctl] <= 1;
    sub_o_cnt <= sub_o_cnt + 1;
    if(sub_o_cnt == DIV-1) begin 
      get_next_sub();
      sub_o_cnt <= 0;
    end
  end
endtask

// Task for addition
task addition(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_add_if.val || (o_add_if.val && o_add_if.rdy)) begin
    o_add_if.val <= 1;
    o_add_if.dat[0 +: ARITH_BITS] <= a[add_o_cnt];
    o_add_if.dat[ARITH_BITS +: ARITH_BITS] <= b[add_o_cnt];
    o_add_if.ctl[5:0] <= ctl;
    o_add_if.sop <= add_o_cnt == 0;
    o_add_if.eop <= add_o_cnt == DIV-1;
    eq_wait[ctl] <= 1;
    add_o_cnt <= add_o_cnt + 1;
    if(add_o_cnt == DIV-1) begin
      get_next_add();
      add_o_cnt <= 0;
    end
  end
endtask

// Task for using multiplies
task multiply(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_mul_if.val || (o_mul_if.val && o_mul_if.rdy)) begin
    o_mul_if.val <= 1;
    o_mul_if.dat[0 +: ARITH_BITS] <= a[mul_o_cnt];
    o_mul_if.dat[ARITH_BITS +: ARITH_BITS] <= b[mul_o_cnt];
    o_mul_if.ctl[5:0] <= ctl;
    o_mul_if.sop <= mul_o_cnt == 0;
    o_mul_if.eop <= mul_o_cnt == DIV-1;
    eq_wait[ctl] <= 1;
    mul_o_cnt <= mul_o_cnt + 1;
    if(mul_o_cnt == DIV-1) begin
      get_next_mul();
      mul_o_cnt <= 0;
    end
  end
endtask


task get_next_mul();
  mul_en <= 1;
  if (~eq_wait[0])
    nxt_mul <= 0;
  else if (eq_val[0] && ~eq_wait[1])
    nxt_mul <= 1;
  else if (eq_val[0] && ~eq_wait[3])
    nxt_mul <= 3;
  else if (~eq_wait[5])
    nxt_mul <= 5;
  else if (eq_val[5] && ~eq_wait[6])
    nxt_mul <= 6;
  else if (eq_val[6] && ~eq_wait[7])
    nxt_mul <= 7;
  else if (eq_val[10] && eq_val[6] && ~eq_wait[11])
    nxt_mul <= 11;
  else if (eq_val[13] && ~eq_wait[14])
    nxt_mul <= 14;
  else if (eq_val[1] && ~eq_wait[2])
    nxt_mul <= 2;
  else if (eq_val[3] && ~eq_wait[4])
    nxt_mul <= 4;
  else
    mul_en <= 0;
endtask;

task get_next_sub();
  sub_en <= 1;
  if (eq_val[8] && eq_val[7] && ~eq_wait[9])
    nxt_sub <= 9;
  else if (eq_val[9] && eq_val[2] && ~eq_wait[10])
    nxt_sub <= 10;
  else if (eq_val[4] && eq_val[11] && ~eq_wait[12])
    nxt_sub <= 12;
  else
    sub_en <= 0;
endtask
  
task get_next_add();
  add_en <= 1;
  if (eq_val[2] && ~eq_wait[8])
    nxt_add <= 8;
  else if (~eq_wait[13])
    nxt_add <= 13;
  else
    add_en <= 0;
endtask  

endmodule