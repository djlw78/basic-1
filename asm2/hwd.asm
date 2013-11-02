section .text
global start
msg: db "alex", 10
start:
push dword 5
push dword msg
push dword 1
mov eax, 4
sub esp, byte 4
int 80h
add esp, 16
push dword 0
mov eax, 1
sub esp, byte 4
int 80h

