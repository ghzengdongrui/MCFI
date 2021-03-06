# exp(x) = 2^hi + 2^hi (2^lo - 1)
# where hi+lo = log2e*x with 128bit precision
# exact log2e*x calculation depends on nearest rounding mode
# using the exact multiplication method of Dekker and Veltkamp

        .global expl
        .align 16, 0x90
        .type expl,@function
expl:
	fldt 8(%rsp)

		# interesting case: 0x1p-32 <= |x| < 16384
		# check if (exponent|0x8000) is in [0xbfff-32, 0xbfff+13]
	mov 16(%rsp), %ax
	or $0x8000, %ax
	sub $0xbfdf, %ax
	cmp $45, %ax
	jbe 2f
	test %ax, %ax
	fld1
	js 1f
		# if |x|>=0x1p14 or nan return 2^trunc(x)
	fscale
	fstp %st(1)
	jmp Ret
		# if |x|<0x1p-32 return 1+x
1:	faddp
	jmp Ret

		# should be 0x1.71547652b82fe178p0L == 0x3fff b8aa3b29 5c17f0bc
		# it will be wrong on non-nearest rounding mode
2:	fldl2e
	subl $48, %esp
		# hi = log2e_hi*x
		# 2^hi = exp2l(hi)
	fmul %st(1),%st
	fld %st(0)
	fstpt (%rsp)
	fstpt 16(%rsp)
	fstpt 32(%rsp)
        .byte 0x90
	call exp2l
__mcfi_dcj_1_exp2l:
		# if 2^hi == inf return 2^hi
	fld %st(0)
	fstpt (%rsp)
	cmpw $0x7fff, 8(%rsp)
	je 1f
	fldt 32(%rsp)
	fldt 16(%rsp)
		# fpu stack: 2^hi x hi
		# exact mult: x*log2e
	fld %st(1)
		# c = 0x1p32+1
	movq $0x41f0000000100000,%rax
	pushq %rax
	fldl (%rsp)
		# xh = x - c*x + c*x
		# xl = x - xh
	fmulp
	fld %st(2)
	fsub %st(1), %st
	faddp
	fld %st(2)
	fsub %st(1), %st
		# yh = log2e_hi - c*log2e_hi + c*log2e_hi
	movq $0x3ff7154765200000,%rax
	pushq %rax
	fldl (%rsp)
		# fpu stack: 2^hi x hi xh xl yh
		# lo = hi - xh*yh + xl*yh
	fld %st(2)
	fmul %st(1), %st
	fsubp %st, %st(4)
	fmul %st(1), %st
	faddp %st, %st(3)
		# yl = log2e_hi - yh
	movq $0x3de705fc2f000000,%rax
	pushq %rax
	fldl (%rsp)
		# fpu stack: 2^hi x lo xh xl yl
		# lo += xh*yl + xl*yl
	fmul %st, %st(2)
	fmulp %st, %st(1)
	fxch %st(2)
	faddp
	faddp
		# log2e_lo
	movq $0xbfbe,%rax
	pushq %rax
	movq $0x82f0025f2dc582ee,%rax
	pushq %rax
	fldt (%rsp)
	addl $40,%esp
		# fpu stack: 2^hi x lo log2e_lo
		# lo += log2e_lo*x
		# return 2^hi + 2^hi (2^lo - 1)
	fmulp %st, %st(2)
	faddp
	f2xm1
	fmul %st(1), %st
	faddp
1:	addl $48, %esp
Ret:    #ret
        popq %rcx
        movl %ecx, %ecx
try:    movq %gs:0x1000, %rdi
__mcfi_bary_expl:     
        movq %gs:(%rcx), %rsi
        cmpq %rdi, %rsi
        jne check
        # addq $1, %fs:0x108 # icj_count
go:
        jmpq *%rcx
check:
        cmpb  $0xfc, %sil
        je    go
        testb $0x1, %sil
        jz die
        cmpl %esi, %edi
        jne try
die:
        leaq try(%rip), %rdi
        jmp __report_cfi_violation_for_return@PLT

        .section	.MCFIFuncInfo,"",@progbits
	.ascii	"{ expl\nY x86_fp80!x86_fp80@\nR expl\n}"
	.byte	0
