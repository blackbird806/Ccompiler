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
movq $255, %r8
movq %r8, -5(%rbp)
movq -5(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movq -5(%rbp), %r8
movq $1, %r9
addq %r8, %r9
lea .LC0(%rip), %rdi
movq %r9, %rsi
xor %eax, %eax
call printf@plt
movq $10, %r8
movq %r8, -4(%rbp)
movq -4(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movq $1, %r8
movq %r8, -4(%rbp)
jmp L0
L1:
movq -4(%rbp), %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
movq -4(%rbp), %r8
movq $1, %r9
addq %r8, %r9
movq %r9, -4(%rbp)
L0:
movq -4(%rbp), %r8
movq $5, %r9
cmpq %r9, %r8
jle L1
movl $0, %eax
popq %rbp
addq $512, %rsp
ret
