.text
.LC0:
.string "num %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$25, %r8
movq	$4, %r9
imulq	%r8, %r9
movq	$2, %r10
movq	$1, %r11
movq	%r10, %rax
cqo
idivq	%r11
movq	%rax, %r11
movq	$8, %r8
imulq	%r11, %r8
movq	$2, %r10
movq	%r8, %rax
cqo
idivq	%r10
movq	%rax, %r10
addq	%r9, %r10
lea .LC0(%rip), %rdi
movq %r10, %rsi
call printf
movq $0, %rax
popq %rbp
ret
