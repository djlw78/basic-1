; utility methods

%define sys_write 4
%define stdout 1

%macro puts 1+
  section .data
  %%msg:
  db %1, 0
  section .text
  pusha
  mov ecx, %%msg
  call write
  popa
%endmacro

section .text

exit:
mov eax, 1
mov ebx, 0
int 80h

write: ; write to stdout - eax ebx edx = *, ecx = str
call strlen ; populates edx
mov eax, 4 ; sys write
mov ebx, 1 ; stdout
int 80h
ret

strlen: ; eax = trash, ecx = str, edx = len out
mov edx, ecx
.a:
mov al, [edx]
cmp al, 0
jz .b
inc edx
jmp .a
.b:
sub edx, ecx
ret
