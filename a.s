.text
.LC0:
.string "out %d\n"
.globl main
main:
pushq   %rbp
movq    %rsp, %rbp
movq $5, %r8
movq $5, %r9
cmpq %r9, %r8
sete %r9b
andq $255, %r9
lea .LC0(%rip), %rdi
movq %r9, %rsi
call printf
movq $5, %r11
movq $1, %r12
cmpq %r12, %r11
sete %r12b
andq $255, %r12
lea .LC0(%rip), %rdi
movq %r12, %rsi
call printf
movq $5, %r14
movq $3, %r15
cmpq %r15, %r14
sete %r15b
andq $255, %r15
lea .LC0(%rip), %rdi
movq %r15, %rsi
call printf
movq $1, %r11
movq $1, %r14
cmpq %r14, %r11
sete %r14b
andq $255, %r14
lea .LC0(%rip), %rdi
movq %r14, %rsi
call printf
movq $0, %rax
popq %rbp
ret
