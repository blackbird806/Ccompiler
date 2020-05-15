.text
.LC0:
.string "num %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$5, %r10
movq %r10, -8(%rbp)
movq	$21, %r12
movq %r12, -16(%rbp)
movq	$5, %r14
movq -8(%rbp), %r15
imulq	%r14, %r15
movq -16(%rbp), %r14
addq	%r15, %r14
lea .LC0(%rip), %rdi
movq %r14, %rsi
call printf
movq $0, %rax
popq %rbp
ret
