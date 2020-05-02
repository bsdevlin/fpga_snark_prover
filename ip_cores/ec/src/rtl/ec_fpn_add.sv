/*
  This performs point addition, allowing arithmetic interfaces to stay at a lower bit width.

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

module ec_fpn_add
#(
  parameter type FP_TYPE,
  parameter type FE_TYPE,
  parameter type FE_TYPE_ARITH      // This is the bit width used in arithmetic blocks - should be a power of 2 
)(
  input i_clk, i_rst,
  // Input points
  if_axi_stream.sink i_pt1_if,
  if_axi_stream.sink i_pt2_if,
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
   These are the equations that need to be computed, they are issued as variables
   become valid. We have a bitmask to track what equation results are valid which
   will trigger other equations. [] show what equations must be valid before this starts.
   We reuse input points (as they are latched) when possible to reduce register usage.
   Taken from https://en.wikibooks.org/wiki/Cryptography/Prime_Curve/Jacobian_Coordinates

   U1 = X1*Z2^2
   U2 = X2*Z1^2
   S1 = Y1*Z2^3
   S2 = Y2*Z1^3
   H = U2 - U1
   R = S2 - S1
   X3 = R^2 - H^3 - 2*U1*H^2
   Y3 = R*(U1*H^2 - X3) - S1*H^3
   Z3 = H*Z1*Z2


   0. A = i_p2.z*i_p2.z mod p
   1. i_p1.x = A * i_p1.x mod p [eq0]           ..U1
   2. C = i_p1.z*i_p1.z mod p
   3. i_p2.x = C * i_p2.x mod p [eq2]        ... U2
   4. A = A * i_p2.z mod p [eq1]
   5. A = A * i_p1.y [eq4]         ... S1
   6. C = C * i_p1.z mod p [eq3]
   7. C = C * i_p2.y mod p [eq6]       .. S2
   8. B = i_p2.x - i_p1.x mod p [eq3, eq1]    .. H
   9. i_p2.y = C - A mod p [eq5,eq7]    ... R
   10. o_p.x = i_p2.y * i_p2.y mod p [eq9]   ... R^2
   11. D = B * B mod p [eq8]         .. H^2
   12. i_p2.x = D * B mod p [eq8, eq11]    ..H^3
   13. o_p.x = o_p.x - i_p2.x mod p [eq12, eq10]
   14. i_p1.x = i_p1.x*D  [eq1, eq8]      ..U1*H^2
   15. o_p.y =  i_p1.x  [eq14]
   16. i_p1.x = 2* i_p1.x mod p [eq15, eq14]
   17. o_p.x = o_p.x - i_p1.x [eq16, eq13]
   18. o_p.y = o_p.y - o_p.x mod p [eq17, eq15]
   19. o_p.y = o_p.y * i_p2.y mod p [eq18, eq9]
   20. i_p2.x = i_p2.x * A [eq5, eq12]
   21. o_p.y = o_p.y - i_p2.x [eq20, eq19]
   22. o_p.z = i_p1.z * i_p2.z mod p
   23. o_p.z = o_p.z * B mod p [eq22, eq8]
 */

 // We also check in the inital state if one of the inputs is "None" (.z == 0), and set the output to the other point
logic [23:0] eq_val, eq_wait;

localparam ARITH_BITS = $bits(FE_TYPE_ARITH);
localparam DIV = $bits(FE_TYPE)/ARITH_BITS;
localparam DIV_LOG2 = DIV == 1 ? 1 : $clog2(DIV);
localparam NUM_WRDS = $bits(FP_TYPE)/ARITH_BITS;

logic [DIV_LOG2-1:0] add_o_cnt, sub_o_cnt, mul_o_cnt;
logic mul_en, add_en, sub_en;
logic [5:0] nxt_mul, nxt_add, nxt_sub;
logic [2:0] o_cnt;

// Temporary variables
FE_TYPE A, B, C, D;
FP_TYPE i_p1_l, i_p2_l, o_p;

logic [$bits(FP_TYPE)/$bits(FE_TYPE_ARITH)-1:0] same_chk, zero_check_p1, zero_check_p2;
logic chks_pass;

enum {IDLE, START, FINISHED} state;

always_comb begin
  chks_pass = ~(&same_chk || &zero_check_p1 || &zero_check_p2);
  i_pt1_if.rdy = (state == IDLE && i_pt1_if.val && i_pt2_if.val);
  i_pt2_if.rdy = (state == IDLE && i_pt1_if.val && i_pt2_if.val);
end


always_ff @ (posedge i_clk) begin
  if (i_rst) begin
    o_pt_if.reset_source();
    o_p <= 0;
    o_mul_if.reset_source();
    o_add_if.reset_source();
    o_sub_if.reset_source();
    i_add_if.rdy <= 0;
    i_mul_if.rdy <= 0;
    i_sub_if.rdy <= 0;
    eq_val <= 0;
    state <= IDLE;
    eq_wait <= 0;
    i_p1_l <= 0;
    i_p2_l <= 0;
    A <= 0;
    B <= 0;
    C <= 0;
    D <= 0;
    same_chk <= 0;
    zero_check_p1 <= 0;
    zero_check_p2 <= 0;
    {add_o_cnt, sub_o_cnt, mul_o_cnt, o_cnt} <= 0;
    {mul_en, add_en, sub_en} <= 0;
    {nxt_mul, nxt_add, nxt_sub} <= 0;
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
        eq_val <= 0;
        eq_wait <= 0;
        A <= 0;
        B <= 0;
        C <= 0;
        D <= 0;
        o_cnt <= 0;
        {mul_en, add_en, sub_en} <= 0;
        {nxt_mul, nxt_add, nxt_sub} <= 0;
        if (i_pt1_if.val && i_pt1_if.rdy && i_pt2_if.val && i_pt2_if.rdy) begin
          i_p1_l <= jb_shift(i_p1_l, i_pt1_if.dat[0 +: ARITH_BITS]);
          i_p2_l <= jb_shift(i_p2_l, i_pt2_if.dat[0 +: ARITH_BITS]);
          same_chk <= {same_chk, i_pt1_if.dat[0 +: ARITH_BITS] == i_pt2_if.dat[0 +: ARITH_BITS]};
          zero_check_p1 <= {zero_check_p1, i_pt1_if.dat[0 +: ARITH_BITS] == 0};
          zero_check_p2 <= {zero_check_p2, i_pt2_if.dat[0 +: ARITH_BITS] == 0};
          if (i_pt1_if.eop) begin  
            state <= START;
          end
        end
      end
      // Just a big if tree where we issue equations if the required inputs
      // are valid
      {START}: begin
        // Some checks on the input points
        if (&same_chk) begin
          state <= FINISHED;
          o_pt_if.err <= 1;
          o_p <= i_p1_l; // Return original point
        end else if (&zero_check_p1) begin
          state <= FINISHED;
          o_p <= i_p2_l; // Return p2
        end else if (&zero_check_p2) begin
          state <= FINISHED;
          o_p <= i_p1_l; // Return p1
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
            1: i_p1_l.x <= fe_shift(i_p1_l.x, i_mul_if.dat);
            2: C <= fe_shift(C, i_mul_if.dat);
            3: i_p2_l.x <= fe_shift(i_p2_l.x, i_mul_if.dat);
            4: A <= fe_shift(A, i_mul_if.dat);
            5: A <= fe_shift(A, i_mul_if.dat);
            6: C <= fe_shift(C, i_mul_if.dat);
            7: C <= fe_shift(C, i_mul_if.dat);
            10: o_p.x <= fe_shift(o_p.x, i_mul_if.dat);
            11: D <= fe_shift(D, i_mul_if.dat);
            12: i_p2_l.x <= fe_shift(i_p2_l.x, i_mul_if.dat);
            14: i_p1_l.x <= fe_shift(i_p1_l.x, i_mul_if.dat);
            19: o_p.y <= fe_shift(o_p.y, i_mul_if.dat);
            20: i_p2_l.x <= fe_shift(i_p2_l.x, i_mul_if.dat);
            22: o_p.z <= fe_shift(o_p.z, i_mul_if.dat);
            23: o_p.z <= fe_shift(o_p.z, i_mul_if.dat);
            default: o_pt_if.err <= 1;
          endcase
        end

        // Check any results from adder
        if (i_add_if.val && i_add_if.rdy) begin
          if (i_add_if.eop) begin
            eq_val[i_add_if.ctl[5:0]] <= 1;
          end
          case(i_add_if.ctl[5:0]) inside
            16: i_p1_l.x <= fe_shift(i_p1_l.x, i_add_if.dat);
            default: o_pt_if.err <= 1;
          endcase
        end

        // Check any results from subtractor
        if (i_sub_if.val && i_sub_if.rdy) begin
          if (i_sub_if.eop) begin
            eq_val[i_sub_if.ctl[5:0]] <= 1;
          end
          case(i_sub_if.ctl[5:0]) inside
            8: B <= fe_shift(B, i_sub_if.dat);
            9: i_p2_l.y <= fe_shift(i_p2_l.y, i_sub_if.dat);
            13: o_p.x <= fe_shift(o_p.x, i_sub_if.dat);
            17: o_p.x <= fe_shift(o_p.x, i_sub_if.dat);
            18: o_p.y <= fe_shift(o_p.y, i_sub_if.dat);
            21: o_p.y <= fe_shift(o_p.y, i_sub_if.dat);
            default: o_pt_if.err <= 1;
          endcase
        end

        if (mul_en)
          case (nxt_mul)
            0: multiply(0, i_p2_l.z, i_p2_l.z);
            1: multiply(1, A, i_p1_l.x);
            2: multiply(2, i_p1_l.z, i_p1_l.z);
            3: multiply(3, C, i_p2_l.x);
            4: multiply(4, A, i_p2_l.z);
            5: multiply(5, A, i_p1_l.y);
            6: multiply(6, C, i_p1_l.z);
            7: multiply(7, C, i_p2_l.y);
            10: multiply(10, i_p2_l.y, i_p2_l.y);
            11: multiply(11, B, B);
            12: multiply(12, D, B);
            14: multiply(14, D, i_p1_l.x);
            19: multiply(19, o_p.y, i_p2_l.y);
            20: multiply(20, i_p2_l.x, A);
            22: multiply(22, i_p1_l.z, i_p2_l.z);
            23: multiply(23, o_p.z, B);
          endcase

        if (add_en)
          case (nxt_add)
            16:addition(16, i_p1_l.x, i_p1_l.x);
          endcase
        
        if (sub_en)
          case (nxt_sub)
            8: subtraction(8, i_p2_l.x, i_p1_l.x);
            9: subtraction(9, C, A);
            13: subtraction(13, o_p.x, i_p2_l.x);
            17: subtraction(17, o_p.x, i_p1_l.x);
            18: subtraction(18, o_p.y, o_p.x);
            21: subtraction(21, o_p.y, i_p2_l.x);
          endcase
        
        // Assignments
        if (eq_val[14] && ~eq_wait[15]) begin                          //15. o_p.y =  i_p1.x  [eq14]
          eq_wait[15] <= 1;
          eq_val[15] <= 1;
          o_p.y <= i_p1_l.x;
        end

        if (&eq_val) begin
          state <= FINISHED;
        end
      end
      {FINISHED}: begin
        same_chk <= 0;
        zero_check_p1 <= 0;
        zero_check_p2 <= 0;
        // Stream out point
        if (~o_pt_if.val || (o_pt_if.val && o_pt_if.rdy)) begin
          o_p <= jb_shift(o_p, 0);
          o_pt_if.dat <= o_p;
          o_pt_if.val <= 1;
          o_pt_if.sop <= o_cnt == 0;
          o_pt_if.eop <= o_cnt == NUM_WRDS-1; 
          o_cnt <= o_cnt + 1;
          if (o_cnt == NUM_WRDS-1) begin
            o_cnt <= 0;
            state <= IDLE;
          end
        end
      end
    endcase
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
      sub_en <= 0;
      eq_wait[ctl] <= 1;
      sub_o_cnt <= 0;
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
      add_en <= 0;
      eq_wait[ctl] <= 1;
      add_o_cnt <= 0;
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
      mul_en <= 0;
      eq_wait[ctl] <= 1;
      mul_o_cnt <= 0;
    end
  end
endtask

task get_next_sub();
  sub_en <= 1;
  if (eq_val[1] && eq_val[3] && ~eq_wait[8])
    nxt_sub <= 8;
  else if (eq_val[5] && eq_val[7] && ~eq_wait[9])
    nxt_sub <= 9;
  else if (eq_val[12] && eq_val[10] && ~eq_wait[13])
    nxt_sub <= 13;
  else if (eq_val[16] && eq_val[13] && ~eq_wait[17])
    nxt_sub <= 17;
  else if (eq_val[17] && eq_val[15] && ~eq_wait[18])
    nxt_sub <= 18;
  else if (eq_val[20] && eq_val[19] && ~eq_wait[21])
    nxt_sub <= 21;
  else
    sub_en <= 0;
endtask

task get_next_add();
  add_en <= 1;
  if (eq_val[15] && eq_val[14] && ~eq_wait[16])
    nxt_add <= 16;
  else
    add_en <= 0;
endtask
  
task get_next_mul();
  mul_en <= 1;
  if (~eq_wait[0] && chks_pass)
    nxt_mul <= 0;
  else if (eq_val[0] && ~eq_wait[1])
    nxt_mul <= 1;
  else if (~eq_wait[2] && chks_pass)
    nxt_mul <= 2;
  else if (eq_val[2] && ~eq_wait[3])
    nxt_mul <= 3;
  else if (eq_val[1] && ~eq_wait[4])
    nxt_mul <= 4;
  else if (eq_val[4] && ~eq_wait[5])
    nxt_mul <= 5;
  else if (eq_val[3] && ~eq_wait[6])
    nxt_mul <= 6;
  else if (eq_val[6] && ~eq_wait[7])
    nxt_mul <= 7;
  else if (eq_val[9] && ~eq_wait[10])
    nxt_mul <= 10;
  else if (eq_val[8] && ~eq_wait[11])
    nxt_mul <= 11;
  else if (eq_val[11] && eq_val[8] && ~eq_wait[12])
    nxt_mul <= 12;
  else if (eq_val[1] && eq_val[11] && ~eq_wait[14])
    nxt_mul <= 14;
  else if (eq_val[18] && eq_val[9] && ~eq_wait[19])
    nxt_mul <= 19;
  else if (eq_val[5] && eq_val[12] && eq_val[13] && ~eq_wait[20])
    nxt_mul <= 20;
  else if (~eq_wait[22] && chks_pass)
    nxt_mul <= 22;
  else if (eq_val[8] && eq_val[22] && ~eq_wait[23])
    nxt_mul <= 23;
  else
    mul_en <= 0;
endtask;

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