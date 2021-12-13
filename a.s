.text
.LC0:
.string "out %d\n"
.text
.globl main
.type main, @function
main:
pushq %rbp
movq %rsp, %rbp
subq $9, %rsp
movq $54, %r8
movl %r8d, -4(%rbp)
movl -4(%rbp), %r8d
movq $546, %r9
addq %r8, %r9
movl %r9d, -8(%rbp)
movl -4(%rbp), %r8d
movl -8(%rbp), %r9d
imulq %r8, %r9
lea .LC0(%rip), %rdi
movq %r9, %rsi
xor %eax, %eax
call printf@plt
movq $45, %r8
movl -4(%rbp), %r9d
addq %r8, %r9
movb %r9b, -9(%rbp)
movb -9(%rbp), %r8b
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movl $0, %eax
popq %rbp
addq $9, %rsp
ret
