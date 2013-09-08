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

%macro putr 1
  section .bss
  %%msg:
  resb 16
  section .text
  pusha
  mov eax, %1
  mov ecx, %%msg
  call itoa
  mov ecx, %%msg
  call write
  popa
%endmacro

section .text

hash: ; ecx=str, ebx=hash, eax=trash
xor ebx, ebx
.a:
movzx eax, byte [ecx]
call islet
jne .b
rol ebx, 7
add ebx, eax
inc ecx
jmp .a
.b:
puts "hash "
putr ebx
puts 10
ret

islet:
cmp eax, byte 'a'
jl .end
cmp eax, byte 'z'
jg .end
cmp eax, eax ; zf=1
.end:
ret

isdig:
cmp eax, byte '0'
jl .end
cmp eax, byte '9'
jg .end
cmp eax, eax ; zf=1
.end:
ret

itoa: ; ecx <= str, eax <= num, ecx => after str
cmp eax, 0
jne .a
mov [ecx], byte '0'	;special case for 0
inc ecx
jmp .end
.a:
mov ebx, 1000000000
mov edx, 0
mov esi, 0
.b:
div ebx			; edx:eax/ebx, eax=quot, edx=rem
or esi, eax		; non zero result yet?
jz .c
add eax, byte '0'
mov [ecx], al
inc ecx
.c:
cmp ebx, 1
jle .end
push edx		; push rem
mov edx, 0
mov eax, ebx
mov ebx, 10
div ebx			; div 10, edx = 0
mov ebx, eax
pop eax			; pop num
jmp .b
.end:
mov [ecx], byte 0
ret

atoi: ; ecx <= str, eax => val
mov eax, 0
mov ebx, 0
.a:
movzx eax, byte [ecx]
call isdig
jne .b
sub al, '0'
imul ebx, 10
add ebx, eax
inc ecx
jmp .a
.b:
mov eax, ebx
ret


read: ; read from stdin - trashes eax, ebx, edx, return ecx = str
mov eax, 3 ; sys_read
mov ebx, 0 ; stdin
mov ecx, readbuf
mov edx, 255 ; len
int 80h
dec eax
mov [ecx+eax], byte 0
ret

exit:
mov eax, 1
mov ebx, 0
int 80h
jmp exit

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

section .bss
readbuf: resb 256
