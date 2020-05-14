.text
.LC0:
.string "num %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq	$5, %r8
movq	$5, %r9
imulq	%r8, %r9
movq	$2, %r10
addq	%r9, %r10
movq	$4, %r11
subq	%r11, %r10
lea .LC0(%rip), %rdi
movq %r10, %rsi
call printf
movq	$25, %r9
movq	$2, %r11
movq	%r9, %rax
cqo
idivq	%r11
movq	%rax, %r11
lea .LC0(%rip), %rdi
movq %r11, %rsi
call printf
movq $0, %rax
popq %rbp
ret
