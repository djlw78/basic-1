; symbol, code, heap dict
; dfind (table,symbol) -> pointer
; dput  (table,symbol,vt,vh,vl)
; dget  (table,symbol) -> vt,vh,vl
; hnew  (size) -> ptr,id
; hdel  (id)
; hget  (id) -> ptr
; copyd (ptr1,ptr2,size)
; copyb (ptr1,ptr2,size)

section .bss

symdict:
resd 1			; size
resd 1000h		; 256 rows of 16b

section .text

dinit:
mov [symdict], 0
ret

dfind:			; ebp=table, edi=sym, zf=found, ebx=offs
mov eax, 0		; eax=low
mov edx, [ebp]		; edx=high
jnz .a
mov ebx, 4
test esp, esp		; clear zf
ret			; RET zf=0,ebx=4 (ins ptr)
.a:
cmp eax, edx		; low - high
jg .nf
mov ecx, eax
add ecx, edx
shl ecx, 1		; ecx=mid
mov ebx, edx
shr ebx, 4		; ebx=mid offs
cmp [ebp+4+ebx], edi
jl .l
jg .g
add ebx, byte 4
ret			; ret ZF=1, ebx=found offs
.l:
mov eax, ecx
inc eax			; low=mid+1
jmp .a
.g:
mov edx, ecx
dec ecx			; high=mid-1
jmp .a
.nf:
mov ebx, eax		; ebx=low (insert index)
add ebx, 4
shr ebx, 4		; ebx=low (insert offs)
ret			; ret ZF=0, ebx=insert offs

dget:			; ebp=table, edi=sym, edx:ebx:eax=val
mov ebp, dict
call dfind
je .f
mov edx, 0
.f:
ret

dput:			; ebp=table, edi=sym, edx:ebx:eax=val
push eax
push ebx
push edx
push edi
call dfind		; returns ebx=offs from ebp+4
je .f
; TODO maybe dfind should return index? so it can be compared with size
cmp [ebp], 100h
jge .ov
mov esi, ebx
mov edi, ebx
add edi, 16

call dins
.f:
pop [ebp+4+eax]
pop [ebp+4+eax+4]
pop [ebp+4+eax+8]
pop [ebp+4+eax+12]
ret
.ov:
puts "dput: overflow", 10
jmp exit

copyd:			; esi=base,edi=dest,eax=count,ebx:ecx=trash
mov ebx, 0
.a:
cmp ecx, eax
je .end
mov ebx, [esi+ecx]
mov [edi+ecx], ebx
add ecx, byte 4
jmp .a
.end:
ret

dins:			; ebp=dict, eax=offs
mov edx, [ebp]
cmp edx, 0xff
je .ov
shr edx, 4
.a:
mov ebx, [edx]
mov ecx, [edx+4]
mov esi, [edx+8]
mov edi, [edx+12]
mov [edx+16], ebx
mov [edx+20], ecx
mov [edx+24], esi
mov [edx+28], edi
sub edx, 16
cmp edx, eax
jg .a
inc [ebp]
ret
.ov:
puts "dins: overflow", 10
jmp exit
