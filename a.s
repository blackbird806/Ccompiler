.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$5, %r8
movq	$3, %r9
imulq	%r8, %r9
movq	$2, %r10
addq	%r9, %r10
movq	$8, %r11
movq	$4, %r8
movq	%r11, %rax
cqo
idivq	%r8
movq	%rax, %r8
addq	%r10, %r8
movq $0, %rax
popq %rbp
ret
