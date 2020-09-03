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
movq $0, %r8
movq %r8, -8(%rbp)
movq -8(%rbp), %r8
movq $0, %r9
cmpq %r9, %r8
jle L1
movq $1, %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
jmp L0
L1:
movq $0, %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
L0:
movq $45, %r8
movq %r8, -8(%rbp)
movq -8(%rbp), %r8
movq $22, %r9
cmpq %r9, %r8
je L2
movq $2, %r8
lea .LC0(%rip), %rdi
movq %r8, %rsi
xor %eax, %eax
call printf@plt
L2:
movl $0, %eax
popq %rbp
addq $512, %rsp
ret
