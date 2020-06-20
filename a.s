.text
.LC0:
.string "out %d\n"
.globl main
main:
pushq %rbp
movq %rsp, %rbp
subq $512, %rsp
movq $100, %r8
movq %r8, -8(%rbp)
jmp L0
L1:
movq -8(%rbp), %r8
movq $20, %r9
cmpq %r9, %r8
jg L2
movq -8(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
L2:
movq -8(%rbp), %r8
movq $1, %r9
subq %r9, %r8
movq %r8, -8(%rbp)
L0:
movq -8(%rbp), %r8
movq $0, %r9
cmpq %r9, %r8
jg L1
addq $512, %rsp
movq $0, %rax
popq %rbp
ret
