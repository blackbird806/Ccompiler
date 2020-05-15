.text
.LC0:
.string "num %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$5, %r10
movq %r10, -4(%rbp)
movq	$22, %r12
movq %r12, -4(%rbp)
movq	$5, %r14
movq -4(%rbp), %r15
imulq	%r14, %r15
lea .LC0(%rip), %rdi
movq %r15, %rsi
call printf
movq $0, %rax
popq %rbp
ret
