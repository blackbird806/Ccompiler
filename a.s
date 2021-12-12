.text
.LC0:
.string "out %d\n"
.text
.globl main
.type main, @function
main:
pushq %rbp
movq %rsp, %rbp
subq $5, %rsp
movq $255, %r8
movl %r8d, -4(%rbp)
movq $255, %r8
movb %r8b, -5(%rbp)
movb -5(%rbp), %r8b
movl -4(%rbp), %r9d
addq %r8, %r9
movb %r9b, -5(%rbp)
movb -5(%rbp), %r8b
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movl $0, %eax
popq %rbp
addq $5, %rsp
ret
