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
dputs "dfind "
dputr edi
dputs 10
mov eax, 0		; eax=low
mov edx, [ebp]		; edx=high
dec edx
.a:
dputs "dfind high "
dputr edx
dputs " low "
dputr eax
dputs 10
cmp eax, edx		; low - high
jg .nf
mov ecx, eax
add ecx, edx		; ecx=low+high
shr ecx, 1		; ecx=mid
dputs "dfind mid "
dputr ecx
dputs 10
mov ebx, ecx
shl ebx, 4
lea ebx, [ebp+ebx+4]	; ebx=mid ptr
dputs "dfind [mid] "
dputr [ebx]
dputs 10
cmp [ebx], edi
jl .l
jg .g
dputs "dfind f", 10
ret			; ret ZF=1, ebx=found ptr, ecx=found index
.l:
dputs "dfind l", 10
mov eax, ecx
inc eax			; low=mid+1
jmp .a
.g:
dputs "dfind g", 10
mov edx, ecx
dec edx			; high=mid-1
jmp .a
.nf:
mov ebx, eax
shl ebx, 4		; ebx=low (insert offs)
lea ebx, [ebp+4+ebx]	; ebx=insert ptr
dputs "dfind nf", 10
test esp, esp
ret			; ret ZF=0, ebx=insert ptr, eax=insert index

sget:
mov ebp, sdict
dget:			; ebp=table, edi=sym, edx:ebx:eax=val
call dfind
jne .nf
mov edx, [ebx+4]
mov eax, [ebx+12]
mov ebx, [ebx+8]
dputs "dget f "
dputr edi
dputs ":"
dputr edx
dputs ":"
dputr ebx
dputs ":"
dputr eax
dputs 10
ret
.nf:
dputs "dget nf", 10
mov edx, 0
mov ebx, 0
mov eax, 0
ret

sput:
dputs "sput", 10
mov ebp, sdict
dput:			; ebp=table, edi=sym, edx:ebx:eax=val
push eax
push ebx
push edx
push edi
call dfind		; returns ebx=offs, eax=index
je .f
dputs "dput add", 10
cmp [ebp], dword DSIZE
jge .ov
mov esi, ebx
lea edi, [ebx+16]
mov edx, [ebp]
sub edx, eax
shl edx, 2		; edx=dwords to copy
mov eax, edx
call copydb
inc dword [ebp]		; increase size
dputs "dput sz now "
dputr [ebp]
dputs 10
.f:
dputs "dput f", 10
pop dword [ebx]
pop dword [ebx+4]
pop dword [ebx+8]
pop dword [ebx+12]
dputs "dput pop "
dputr [ebx]
dputs ":"
dputr [ebx+4]
dputs ":"
dputr [ebx+8]
dputs ":"
dputr [ebx+12]
dputs 10
ret
.ov:
dputs "dput: overflow", 10
jmp exit

copydb:			; esi=src,edi=dest,eax=count,ebx=preserved
dputs "copyd "
dputr eax
dputs 10
shl eax, 2
.a:
test eax, eax
je .end
sub eax, byte 4
dputs "copyd a "
dputr eax
dputs " "
dputr [esi+eax]
dputs 10
mov edx, [esi+eax]
mov [edi+eax], edx
jmp .a
.end:
ret

copydf:			; esi=src,edi=dest,eax=count,ebx=preserved
dputs "copyd "
dputr eax
dputs 10
mov ecx, 0		; FIXME copy backwards not forwards...
shl eax, 2
.a:
cmp ecx, eax
je .end
dputs "copyd a "
dputr ecx
dputs " "
dputr [esi+ecx]
dputs 10
mov edx, [esi+ecx]
mov [edi+ecx], edx
add ecx, byte 4
jmp .a
.end:
ret

