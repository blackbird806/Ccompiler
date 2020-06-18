.text
.LC0:
.string "out %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq $2, %r8
movq $2, %r9
cmpq %r9, %r8
je L1
movq $3, %r10
movq $3, %r11
imulq %r10, %r11
lea .LC0(%rip), %rdi
movq %r11, %rsi
call printf
jmp L0
L1:
movq $48, %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
call printf
L0:
movq $0, %rax
popq %rbp
ret
