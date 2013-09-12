%macro puts 1+
  section .data
  %%msg:
  db %1
  %%msgl:
  dd $-%%msg
  section .text
  pusha
  mov ecx, %%msg
  mov edx, dword [%%msgl]
  call write
  popa
%endmacro

%macro dputs 1+
%ifdef D
  pushf
  puts %1
  popf
%endif
%endmacro

%macro putr 1
  pusha
  mov eax, %1
  mov ecx, putrbuf
  call itoa
  mov ecx, putrbuf
  call writes
  popa
%endmacro

%macro dputr 1
%ifdef D
  pushf
  putr %1
  popf
%endif
%endmacro

section .bss

putrbuf: resb 16

section .text

hash: ; ecx=str, edi=hash, ebp=preserved
mov edi, 0
.a:
movzx eax, byte [ecx]
call islet
jne .b
rol edi, 7
add edi, eax
inc ecx
jmp .a
.b:
dputs "hash "
dputr edi
dputs 10
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

itoa: ; ecx=str, eax=num, ecx=after str
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

atoi: ; ecx=str, eax=val
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

reads: ; ecx=str, eax=len
mov eax, 3		; sys_read
mov ebx, 0		; stdin
mov edx, 255		; max len
int 80h
dec eax
mov [ecx+eax], byte 0
ret

exit:
mov eax, 1		; sys_exit
mov ebx, 0		; exit status
int 80h
jmp exit

writes: ; ecx=str
call strlen ; populates edx
write: ; write to stdout - ecx=str, edx=len
mov eax, 4 ; sys_write
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

