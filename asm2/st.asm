struc ste
.sym resd 1
.hi resd 1
.lo resd 1
endstruc

section .text

stfind: ; ebx=sym, esi=offs, zf=found, ecx=preserved
mov esi, 0
.a:
cmp [st+esi+ste.sym], ebx
je .end
add esi, ste_size
cmp esi, 64 * ste_size
jl .a
cmp esi, 0 ; zf=0
.end:
ret

stput: ; ebx=sym, edx:eax=val, ecx=preserved
call stfind
je .f
push ebx	; push orig sym
mov ebx, 0
call stfind
pop ebx		; pop orig sym
mov [st+esi+ste.sym], ebx
.f:
mov [st+esi+ste.hi], edx
mov [st+esi+ste.lo], eax
ret

stget: ; ebx=sym, edx:eax=value, ecx=preserved
call stfind
je .f
mov eax, 0
mov edx, 0
ret
.f:
mov edx, [st+esi+ste.hi]
mov eax, [st+esi+ste.lo]
ret

section .data

st:
%rep 64
istruc ste
at ste.sym, dd 0
iend
%endrep
