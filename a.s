.text
.LC0:
.string "num %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$5, %r8
movq	$2, %r9
imulq	%r8, %r9
movq	$12, %r10
addq	%r9, %r10
lea .LC0(%rip), %rdi
movq %r10, %rsi
call printf
movq $0, %rax
popq %rbp
ret
