struc ste
.sym resd 1
.typ resd 1
.hi resd 1
.lo resd 1
endstruc

section .text

stfind: ; edi{ebx}=sym, esi=offs, zf=found, ecx=preserved
mov esi, 0
.a:
cmp [st+esi+ste.sym], edi
je .end
add esi, ste_size
cmp esi, 64 * ste_size
jl .a
cmp esi, 0 ; zf=0
.end:
ret

stput: ; edi{ebx}=sym, edx:ebx:eax=val, ecx=preserved
call stfind
je .f
push edi	; push orig sym
mov edi, 0
call stfind
pop edi		; pop orig sym
mov [st+esi+ste.sym], edi
.f:
mov [st+esi+ste.typ], edx
mov [st+esi+ste.hi], ebx
mov [st+esi+ste.lo], eax
ret

stget: ; edi{ebx}=sym, edx:ebx:eax=value, ecx=preserved
call stfind
je .f
mov edx, 0
ret
.f:
mov edx, [st+esi+ste.typ]
mov ebx, [st+esi+ste.hi]
mov eax, [st+esi+ste.lo]
ret

section .data

st:
%rep 64
istruc ste
at ste.sym, dd 0
iend
%endrep
