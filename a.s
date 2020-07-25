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
movq $54, %r8
movq %r8, -8(%rbp)
movq -8(%rbp), %r8
movq $546, %r9
addq %r8, %r9
movq %r9, -16(%rbp)
movq -8(%rbp), %r8
movq -16(%rbp), %r9
imulq %r8, %r9
lea .LC0(%rip), %rdi
movq %r9, %rsi
xor %eax, %eax
call printf@plt
movq $45, %r8
movq -8(%rbp), %r9
addq %r8, %r9
movb %r9, -17(%rbp)
movb -17(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movl $0, %eax
popq %rbp
addq $512, %rsp
ret
