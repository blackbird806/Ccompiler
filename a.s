.text
.LC0:
.string "out %d\n"
.globl main
main:
pushq %rbp
movq %rsp, %rbp
subq $512, %rsp
movq $5, %r8
movq %r8, -8(%rbp)
movq -8(%rbp), %r8
movq %r8, -32(%rbp)
movq $4, %r8
movq %r8, -16(%rbp)
movq $0, %r8
movq %r8, -24(%rbp)
jmp L0
L1:
movq -8(%rbp), %r8
movq -32(%rbp), %r9
imulq %r8, %r9
movq %r9, -8(%rbp)
movq -24(%rbp), %r8
movq $1, %r9
addq %r8, %r9
movq %r9, -24(%rbp)
L0:
movq -24(%rbp), %r8
movq -16(%rbp), %r9
movq $1, %r10
subq %r10, %r9
cmpq %r9, %r8
jl L1
movq -8(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
addq $512, %rsp
movq $0, %rax
popq %rbp
ret
