/* hppa1.1   addmul_1 -- Multiply a limb vector with a limb and add
 *			 the result to a second limb vector.
 *
 *      Copyright (C) 1992, 1993, 1994, 1998,
 *                    2001 Free Software Foundation, Inc.
 *
 * This file is part of GnuPG.
 *
 * GnuPG is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * GnuPG is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *
 * Note: This code is heavily based on the GNU MP Library.
 *	 Actually it's the same code with only minor changes in the
 *	 way the data is stored; this is to support the abstraction
 *	 of an optional secure memory allocation which may be used
 *	 to avoid revealing of sensitive data due to paging etc.
 *	 The GNU MP Library itself is published under the LGPL;
 *	 however I decided to publish this code under the plain GPL.
 */


/*******************
 * mpi_limb_t
 * mpihelp_addmul_1( mpi_ptr_t res_ptr,      (r26)
 *		     mpi_ptr_t s1_ptr,	     (r25)
 *		     mpi_size_t s1_size,     (r24)
 *		     mpi_limb_t s2_limb)     (r23)
 *
 * This runs at 11 cycles/limb on a PA7000.  With the used instructions, it
 * can not become faster due to data cache contention after a store.  On the
 * PA7100 it runs at 10 cycles/limb, and that can not be improved either,
 * since only the xmpyu does not need the integer pipeline, so the only
 * dual-issue we will get are addc+xmpyu.  Unrolling could gain a cycle/limb
 * on the PA7100.
 *
 * There are some ideas described in mul1.S that applies to this code too.
 */

	.code
	.export 	mpihelp_addmul_1
mpihelp_addmul_1
	.proc
	.callinfo	frame=64,no_calls
	.entry

	ldo		64(%r30),%r30
	fldws,ma	4(%r25),%fr5
	stw		%r23,-16(%r30)		; move s2_limb ...
	addib,= 	-1,%r24,L$just_one_limb
	 fldws		-16(%r30),%fr4		; ... into fr4
	add		%r0,%r0,%r0		; clear carry
	xmpyu		%fr4,%fr5,%fr6
	fldws,ma	4(%r25),%fr7
	fstds		%fr6,-16(%r30)
	xmpyu		%fr4,%fr7,%fr8
	ldw		-12(%r30),%r19		; least significant limb in product
	ldw		-16(%r30),%r28

	fstds		%fr8,-16(%r30)
	addib,= 	-1,%r24,L$end
	 ldw		-12(%r30),%r1

; Main loop
L$loop	ldws		0(%r26),%r29
	fldws,ma	4(%r25),%fr5
	add		%r29,%r19,%r19
	stws,ma 	%r19,4(%r26)
	addc		%r28,%r1,%r19
	xmpyu		%fr4,%fr5,%fr6
	ldw		-16(%r30),%r28
	fstds		%fr6,-16(%r30)
	addc		%r0,%r28,%r28
	addib,<>	-1,%r24,L$loop
	 ldw		-12(%r30),%r1

L$end	ldw		0(%r26),%r29
	add		%r29,%r19,%r19
	stws,ma 	%r19,4(%r26)
	addc		%r28,%r1,%r19
	ldw		-16(%r30),%r28
	ldws		0(%r26),%r29
	addc		%r0,%r28,%r28
	add		%r29,%r19,%r19
	stws,ma 	%r19,4(%r26)
	addc		%r0,%r28,%r28
	bv		0(%r2)
	 ldo		-64(%r30),%r30

L$just_one_limb
	xmpyu		%fr4,%fr5,%fr6
	ldw		0(%r26),%r29
	fstds		%fr6,-16(%r30)
	ldw		-12(%r30),%r1
	ldw		-16(%r30),%r28
	add		%r29,%r1,%r19
	stw		%r19,0(%r26)
	addc		%r0,%r28,%r28
	bv		0(%r2)
	 ldo		-64(%r30),%r30

	.exit
	.procend


