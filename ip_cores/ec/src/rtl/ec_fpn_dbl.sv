/*
  This performs point doubling on a prime field Fp_n using jacobian points.
  
  Inputs and outputs are all AXI streams with the data width being the lowest element (FE_TYPE_ARITH),
  in order to help with timing.

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
  if_axi_stream.sink   i_pt_if,
  // Output point
  if_axi_stream.source o_pt_if,
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
localparam NUM_WRDS = $bits(FP_TYPE)/ARITH_BITS;

logic [DIV_LOG2-1:0] add_o_cnt, sub_o_cnt, mul_o_cnt;
logic [2:0] o_cnt;
logic mul_en, add_en, sub_en;
logic [5:0] nxt_mul, nxt_add, nxt_sub;

// Temporary variables
FE_TYPE A, B, C, D, E;
FP_TYPE i_p_l, o_p;
logic [$bits(FP_TYPE)-1:0] o_p_flat;
logic [$bits(FP_TYPE)/$bits(FE_TYPE_ARITH)-1:0] zero_check;
logic chks_pass;

always_comb begin
  chks_pass = ~(&zero_check);
end

enum {IDLE, START, FINISHED} state;
always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    i_pt_if.rdy <= 0;
    o_pt_if.reset_source();
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
    o_p_flat <= 0;
    o_p <= 0;
    A <= 0;
    B <= 0;
    C <= 0;
    D <= 0;
    E <= 0;
    {add_o_cnt, sub_o_cnt, mul_o_cnt, o_cnt} <= 0;
    {mul_en, add_en, sub_en} <= 0;
    {nxt_mul, nxt_add, nxt_sub} <= 0;  
    zero_check <= 0;
  end else begin
    
    i_mul_if.rdy <= 1;
    i_add_if.rdy <= 1;
    i_sub_if.rdy <= 1;

    if (o_mul_if.rdy) o_mul_if.val <= 0;
    if (o_add_if.rdy) o_add_if.val <= 0;
    if (o_sub_if.rdy) o_sub_if.val <= 0;
    if (o_pt_if.rdy) begin
      o_pt_if.val <= 0;
      if (o_pt_if.eop && o_pt_if.val) o_pt_if.err <= 0;
    end

    case(state)
      {IDLE}: begin
        i_pt_if.rdy <= 1;
        eq_val <= 0;
        eq_wait <= 0;
        o_pt_if.err <= 0;
        A <= 0;
        B <= 0;
        C <= 0;
        D <= 0;
        E <= 0;
        zero_check <= 0;
        {mul_en, add_en, sub_en} <= 0;
        {nxt_mul, nxt_add, nxt_sub} <= 0;        
        if (i_pt_if.val && i_pt_if.rdy) begin
          i_p_l <= jb_shift(i_p_l, i_pt_if.dat[0 +: ARITH_BITS]);
          zero_check <= {zero_check, i_pt_if.dat[0 +: ARITH_BITS] == 0};
          if (i_pt_if.eop) begin
              state <= START;
              i_pt_if.rdy <= 0;
           end
        end
      end
      // Just a big if tree where we issue equations if the required inputs
      // are valid
      {START}: begin
        i_mul_if.rdy <= 1;
        
        if (&zero_check) begin
          state <= FINISHED;
          o_p_flat <= 0;
        end
        
        if (~sub_en) get_next_sub();
        if (~add_en) get_next_add();
        if (~mul_en) get_next_mul();

        // Check any results from multiplier
        if (i_mul_if.val && i_mul_if.rdy) begin
          if (i_mul_if.eop) begin
            eq_val[i_mul_if.ctl[5:0]] <= 1;
          end
          case(i_mul_if.ctl[5:0]) inside
            0: A <= fe_shift(A, i_mul_if.dat);
            1: B <= fe_shift(B, i_mul_if.dat);
            2: B <= fe_shift(B, i_mul_if.dat);
            3: C <= fe_shift(C, i_mul_if.dat);
            4: C <= fe_shift(C, i_mul_if.dat);
            5: D <= fe_shift(D, i_mul_if.dat);
            6: D <= fe_shift(D, i_mul_if.dat);
            7: o_p.x <= fe_shift(o_p.x, i_mul_if.dat);
            11: o_p.y <= fe_shift(o_p.y, i_mul_if.dat);
            14: o_p.z <= fe_shift(o_p.z, i_mul_if.dat);
            default: o_pt_if.err <= 1;
          endcase
        end

        // Check any results from adder
        if (i_add_if.val && i_add_if.rdy) begin
          if (i_add_if.eop) begin
            eq_val[i_add_if.ctl[5:0]] <= 1;
          end
          case(i_add_if.ctl[5:0]) inside
            8: E <= fe_shift(E, i_add_if.dat);
            13: o_p.z <= fe_shift(o_p.z, i_add_if.dat);
            default: o_pt_if.err <= 1;
          endcase
        end

        // Check any results from subtractor
        if (i_sub_if.val && i_sub_if.rdy) begin
          if (i_sub_if.eop) begin
            eq_val[i_sub_if.ctl[5:0]] <= 1;
          end
          case(i_sub_if.ctl[5:0]) inside
            9: o_p.x <= fe_shift(o_p.x, i_sub_if.dat);
            10: o_p.y <= fe_shift(o_p.y, i_sub_if.dat);
            12: o_p.y <= fe_shift(o_p.y, i_sub_if.dat);
            default: o_pt_if.err <= 1;
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
        else if (sub_en)
          case (nxt_sub)
            9: subtraction(9, o_p.x, E);
            10: subtraction(10, B, o_p.x);
            12: subtraction(12, o_p.y, C);
          endcase
        else if (add_en)
          case (nxt_add)
            8: addition(8, B, B);
            13: addition(13, i_p_l.y, i_p_l.y);
          endcase

        if (&eq_val) begin
          state <= FINISHED;
          o_p_flat <= o_p;
        end
      end
      {FINISHED}: begin
        // Stream out point
        if (~o_pt_if.val || (o_pt_if.val && o_pt_if.rdy)) begin
          o_pt_if.dat <= o_p_flat;
          o_p_flat <= o_p_flat >> $bits(FE_TYPE_ARITH);
          o_pt_if.val <= 1;
          o_pt_if.sop <= o_cnt == 0;
          o_pt_if.eop <= o_cnt == NUM_WRDS-1; 
          o_cnt <= o_cnt + 1;
          if (o_cnt == NUM_WRDS-1) begin
            o_cnt <= 0;
            state <= IDLE;
            i_pt_if.rdy <= 1;
          end
        end
      end
    endcase

    if (o_pt_if.err & ~o_pt_if.val) begin
      o_pt_if.val <= 1;
      if (o_pt_if.rdy) begin
        o_pt_if.err <= 0;
        state <= IDLE;
      end
    end

  end
end

// Task for subtractions
task subtraction(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_sub_if.val || (o_sub_if.val && o_sub_if.rdy)) begin
    o_sub_if.val <= 1;
    o_sub_if.dat[0 +: ARITH_BITS] <= fe_select(a, sub_o_cnt);
    o_sub_if.dat[ARITH_BITS +: ARITH_BITS] <= fe_select(b, sub_o_cnt);
    o_sub_if.ctl[5:0] <= ctl;
    o_sub_if.sop <= sub_o_cnt == 0;
    o_sub_if.eop <= sub_o_cnt == DIV-1;  
    sub_o_cnt <= sub_o_cnt + 1;
    if(sub_o_cnt == DIV-1) begin
      sub_o_cnt <= 0;
      eq_wait[ctl] <= 1;
      sub_en <= 0;
    end
  end
endtask

// Task for addition
task addition(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_add_if.val || (o_add_if.val && o_add_if.rdy)) begin
    o_add_if.val <= 1;
    o_add_if.dat[0 +: ARITH_BITS] <= fe_select(a, add_o_cnt);
    o_add_if.dat[ARITH_BITS +: ARITH_BITS] <= fe_select(b, add_o_cnt);
    o_add_if.ctl[5:0] <= ctl;
    o_add_if.sop <= add_o_cnt == 0;
    o_add_if.eop <= add_o_cnt == DIV-1;
    add_o_cnt <= add_o_cnt + 1;
    if(add_o_cnt == DIV-1) begin
      add_o_cnt <= 0;
      eq_wait[ctl] <= 1;
      add_en <= 0;
    end
  end
endtask

// Task for using multiplies
task multiply(input int unsigned ctl, input FE_TYPE a, b);
  if (~o_mul_if.val || (o_mul_if.val && o_mul_if.rdy)) begin
    o_mul_if.val <= 1;
    o_mul_if.dat[0 +: ARITH_BITS] <= fe_select(a, mul_o_cnt);
    o_mul_if.dat[ARITH_BITS +: ARITH_BITS] <= fe_select(b, mul_o_cnt);
    o_mul_if.ctl[5:0] <= ctl;
    o_mul_if.sop <= mul_o_cnt == 0;
    o_mul_if.eop <= mul_o_cnt == DIV-1;
    mul_o_cnt <= mul_o_cnt + 1;
    if(mul_o_cnt == DIV-1) begin
      mul_o_cnt <= 0;
      eq_wait[ctl] <= 1;
      mul_en <= 0;
    end
  end
endtask


task get_next_mul();
  mul_en <= 1;
  if (~eq_wait[0] && chks_pass)
    nxt_mul <= 0;
  else if (eq_val[0] && ~eq_wait[1])
    nxt_mul <= 1;
  else if (eq_val[0] && ~eq_wait[3])
    nxt_mul <= 3;
  else if (~eq_wait[5] && chks_pass)
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
  else if (~eq_wait[13] && chks_pass)
    nxt_add <= 13;
  else
    add_en <= 0;
endtask 

function FP_TYPE jb_shift(input FP_TYPE p, input logic [ARITH_BITS-1:0] dat);
  logic [$bits(FP_TYPE)-1:0] p_;
  p_ = p;
  p_ = {dat, p[$bits(FP_TYPE)-1:ARITH_BITS]};
  jb_shift = p_;
endfunction 
  
function FE_TYPE fe_shift(input FE_TYPE fe, input logic [ARITH_BITS-1:0] dat);
  logic [$bits(FE_TYPE)-1:0] fe_;
  fe_ = fe;
  if (ARITH_BITS == $bits(FE_TYPE))
    fe_ = dat;
  else  
    fe_ = {dat, fe_[$bits(FE_TYPE)-1:ARITH_BITS]};
  fe_shift = fe_;
endfunction 

function logic [ARITH_BITS-1:0] fe_select(input FE_TYPE fe, input int select);
  logic [$bits(FE_TYPE)-1:0] fe_;
  fe_ = fe;
  fe_select = fe_[select*ARITH_BITS +: ARITH_BITS];
endfunction 

endmodule