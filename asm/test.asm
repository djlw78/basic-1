; example assembly program using utility methods
; nasm -f elf test.asm && gcc test.o -o test && ./test

%include "util.asm"

global main
section .text

main:
mov ecx, msg
call write
puts "unf", 10
call exit

section .data
msg: db "hello", 10, 0
