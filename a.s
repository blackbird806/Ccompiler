.text
.LC0:
.string "out %d\n"
.text
.globl main
.type main, @function
main:
pushq %rbp
movq %rsp, %rbp
subq $512, %rsp
movq $5, %r8
movq %r8, -8(%rbp)
movq -8(%rbp), %r8
movq $1, %r9
subq %r9, %r8
movq %r8, -16(%rbp)
movq -8(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movl $0, %eax
popq %rbp
addq $512, %rsp
ret
