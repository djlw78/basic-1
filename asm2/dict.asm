; symbol, code, heap dict
; dfind (table,symbol) -> pointer
; dput  (table,symbol,vt,vh,vl)
; dget  (table,symbol) -> vt,vh,vl
; hnew  (size) -> ptr,id
; hdel  (id)
; hget  (id) -> ptr
; copyd (ptr1,ptr2,size)
; copyb (ptr1,ptr2,size)

%define DSIZE 100h

section .bss

sdict:
resd 1			; size
times DSIZE resd 4

section .text

dfind:			; ebp=table, edi=sym, zf=found, ebx=ptr
puts "dfind", 10
mov eax, 0		; eax=low
mov edx, [ebp]		; edx=high
dec edx
;test edx, edx
;puts "dfind high "
;putr edx
;puts 10
;jnz .a
;lea ebx, [ebp+4]	; ebx=insert ptr
;test esp, esp		; clear zf
;puts "dfind nf0", 10
;ret			; RET zf=0, ebx=insert ptr, eax=insert index
.a:
puts "dfind high "
putr edx
puts " low "
putr eax
puts 10
cmp eax, edx		; low - high
jg .nf
mov ecx, eax
add ecx, edx		; ecx=low+high
shr ecx, 1		; ecx=mid
puts "dfind mid "
putr ecx
puts 10
mov ebx, ecx
shl ebx, 4
lea ebx, [ebp+ebx+4]	; ebx=mid ptr
puts "dfind [mid] "
putr [ebx]
puts 10
cmp [ebx], edi
jl .l
jg .g
puts "dfind f", 10
ret			; ret ZF=1, ebx=found ptr, ecx=found index
.l:
puts "dfind l", 10
mov eax, ecx
inc eax			; low=mid+1
jmp .a
.g:
puts "dfind g", 10
mov edx, ecx
dec edx			; high=mid-1
jmp .a
.nf:
mov ebx, eax
shl ebx, 4		; ebx=low (insert offs)
lea ebx, [ebp+4+ebx]	; ebx=insert ptr
puts "dfind nf", 10
test esp, esp
ret			; ret ZF=0, ebx=insert ptr, eax=insert index

sget:
mov ebp, sdict
dget:			; ebp=table, edi=sym, edx:ebx:eax=val
call dfind
jne .nf
mov edx, [ebx+4]
mov ebx, [ebx+8]
mov eax, [ebx+12]
ret
.nf:
mov edx, 0
mov ebx, 0
mov eax, 0
ret

sput:
puts "sput", 10
mov ebp, sdict
dput:			; ebp=table, edi=sym, edx:ebx:eax=val
push eax
push ebx
push edx
push edi
call dfind		; returns ebx=offs, eax=index
je .f
puts "dput add", 10
cmp [ebp], dword DSIZE
jge .ov
mov esi, ebx
lea edi, [ebx+16]
mov edx, [ebp]
sub edx, eax
shl edx, 2		; edx=dwords to copy
mov eax, edx
call copyd
inc dword [ebp]		; increase size
puts "dput sz now "
putr [ebp]
puts 10
.f:
puts "dput f", 10
pop dword [ebx]
pop dword [ebx+4]
pop dword [ebx+8]
pop dword [ebx+12]
ret
.ov:
puts "dput: overflow", 10
jmp exit

copyd:			; esi=src,edi=dest,eax=count,ebx=preserved
puts "copyd "
putr eax
puts 10
mov ecx, 0		; FIXME copy backwards not forwards...
shl eax, 2
.a:
cmp ecx, eax
je .end
puts "copyd a "
putr ecx
puts " "
putr [esi+ecx]
puts 10
mov edx, [esi+ecx]
mov [edi+ecx], edx
add ecx, byte 4
jmp .a
.end:
ret

