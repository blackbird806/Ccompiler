.text
.LC0:
.string "out %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq $2, %r8
movq $5, %r9
cmpq %r9, %r8
jg L0
movq $5, %r10
lea .LC0(%rip), %rdi
movq %r10, %rsi
call printf
L0:
movq $5, %r8
movq $2, %r9
cmpq %r9, %r8
jg L2
movq $3, %r10
lea .LC0(%rip), %rdi
movq %r10, %rsi
call printf
L2:
movq $0, %rax
popq %rbp
ret
