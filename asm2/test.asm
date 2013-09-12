; headache inducing basic interpreter
; nasm -f elf test.asm && ld test.o && ./a.out

%include "util.asm"
%include "dict.asm"

%define SYM 1
%define NUM 2
%define STR 3
%define CHR 4
%define FUN 5

section .data

str: db "!",0
.print: db "print",0
.let: db "let",0
.input: db "input",0
.x: db "x",0

section .bss

buf: db "!", 0
.input: resb 100h
.print: resb 100h
.prompt: resb 100h
hn: resd 1
heap: resb 10000h

section .text

global _start

_start:
puts "BASIC2", 10, 10

mov [hn], dword heap		; init heap ptr
mov [sdict], dword 0

mov ecx, str.print
call hash
mov edx, FUN
mov ebx, 0
mov eax, basicprint
call sput

mov ecx, str.let
call hash
mov edx, FUN
mov ebx, 0
mov eax, basiclet
call sput

mov ecx, str.x
call hash
mov edx, NUM
mov ebx, 0
mov eax, 123
call sput

mov ecx, str.input
call hash
mov edx, FUN
mov ebx, 0
mov eax, basicinput
call sput

prompt:
puts ">"
mov ecx, buf.prompt
call reads
call gnt		; populates edi:edx:ebx:eax
cmp edx, 0
je prompt
cmp edx, SYM
je .sym
; TODO define line
puts "unexpected token "
putr edx
puts 10
jmp prompt
.sym:
push ecx
call sget		; populates edx:ebx:eax
pop ecx
cmp edx, FUN
je .sym2
; TODO call let
puts "unknown symbol", 10
jmp prompt
.sym2:
dputs "pr cmd "
dputr eax
dputs 10
call eax		; call the basic command...
jmp prompt

basicinput: ; INPUT sym
call gnt
cmp edx, SYM
je .s
puts "input: expected symbol", 10
ret
.s:
push edi
puts "? "
mov ecx, buf.input
call reads
call atoi
pop edi
mov edx, NUM
mov ebx, 0
call sput
ret

basiclet: ; LET sym = exp
; let x = 10
call gnt
cmp edx, SYM
je .s
puts "let: missing symbol", 10
ret
.s:
push edi		; push the symbol
call gnt
cmp edx, CHR
je .c
add esp, byte 4
puts "let: missing =", 10
ret
.c:
cmp eax, byte '='
je .c2
add esp, byte 4
puts "let: not an =", 10
ret
.c2:
call gne
cmp edx, 0
jne .e
puts "let: missing expression", 10
add esp, byte 4
ret
.e:
pop edi
call sput		; associate symbol with value...
ret


basicprint: 		; PRINT {exp} [;]
dputs "basicprint",10
; print x
; print x + 10
.a:
call gne
cmp edx, NUM
je .num
cmp edx, STR
je .str
puts 10
ret
.str: ; eax=str, ebx=len
push ecx
mov ecx, eax
mov edx, ebx
call write
pop ecx
jmp .a
.num: ; eax=num
push ecx
mov ecx, buf.print
call itoa
mov ecx, buf.print
call writes
pop ecx
jmp .a




gne: ; get next expression - ecx=str, edx=type(2=num,3=str), ebx:eax=val
dputs "gne", 10
; exp = val [chr exp]
call gnv
cmp edx, 0
jne .b
ret
.b:
push ecx		; push str ptr
push edx		; push type
push ebx		; push hi val
push eax		; push lo val
call gnt		; see if next token is chr
cmp edx, CHR
je .c
pop eax			; pop lo val
pop ebx			; pop hi val
pop edx			; pop type
pop ecx			; pop str
ret			; return, no expression, just a value
.c:
dputs "gne chr", 10
push eax		; push the chr
call gne		; populates edx:ebx:eax...
cmp edx, 0
jne .d
puts "gne: missing expression", 10
add esp, byte 20
mov edx, 0
ret
.d:
mov [esp+16],ecx	; update str ptr on stack - bit of a hack
pop ecx			; pop chr
pop esi			; pop orig lo val
pop ebp			; pop orig hi val
pop edi			; pop orig type
dputs "gne eval "
dputr esi
dputs " <"
dputr ecx
dputs "> "
dputr eax
dputs 10
; [esp]=ecx
; ---- evaluate edx:ebx:eax = edi:ebp:esi *ecx* edx:ebx:eax ----
cmp edi, NUM
je .num
puts "gne: bad expression", 10
add esp, byte 4
mov edx, 0
ret
.num:
dputs "gne num", 10
cmp edx, NUM
je .num2
puts "gne: bad numeric expression", 10
add esp, byte 4
mov edx, 0
ret
.num2:
mov edx, NUM
cmp ecx, byte '+'
je .nadd
cmp ecx, byte '-'
je .nsub
cmp ecx, byte '='
je .neq
cmp ecx, byte '*'
je .nmul
puts "gne: bad numeric operator", 10
add esp, byte 4
mov edx, 0
ret
.nadd:
add eax, esi
jmp .end
.nsub:
sub esi, eax
mov eax, esi
jmp .end
.neq:
; could use a boolean type...
cmp eax, esi
je .neqe
mov eax, 0
jmp .end
.neqe:
mov eax, 1
jmp .end
.nmul:
dputs "gne.nmul", 10
imul eax, esi
.end:
pop ecx			; overwrite op with str ptr
dputs "gne: eval ret "
dputr eax
dputs 10
ret


gnv: ; get next value - ecx=str, edx=type(2=num,3=str) ebx:eax=value
; val = num | str | sym | (exp)
dputs "gnv", 10
call gnt
cmp edx, SYM
je .s
cmp edx, byte NUM
je .end
cmp edx, byte STR
je .end
; TODO exp
mov edx, 0
ret
.s:
push ecx
call sget		; might be function...
pop ecx
.end:
ret


gnt: ; get next token - ecx=str, edx=type(1=sym,2=num,3=str,4=chr), ebx:eax=val, edi=hash
dputs "gnt", 10
movzx eax, byte [ecx]
cmp eax, byte ' '
je .sp
cmp eax, byte '"'
je .str
call isdig
je .dig
call islet
je .let
test eax, 7fh
jnz .chr
mov edx, 0		; invalid char, end of line
dputs "gnt: nul", 10
ret
.sp:
inc ecx
jmp gnt
.str:
dputs "gnt: str", 10
inc ecx			; first char of string
mov ebx, 0		; string len
.str1:
movzx eax, byte [ecx+ebx]
cmp eax, byte 0		; end of src
je .strnul
cmp eax, byte '"'	; end of str literal
je .strend
inc ebx			; ebx=str len FIXME gne doesn't preserve ebx
jmp .str1
.strnul:
puts "gnt: no closing quote", 10
mov edx, 0
ret
.strend:
mov eax, ecx		; eax=start of str
add ecx, ebx
inc ecx			; ecx=char after str
mov edx, STR
ret
.dig:
dputs "gnt: dig", 10
call atoi
mov edx, NUM
ret
.let:
dputs "gnt: let", 10
call hash		; populates edi
mov edx, SYM
ret
.chr:
inc ecx
mov edx, CHR
ret



copy: ; ecx=src, eax=dest, ebx=size
mov esi, 0
.c1:
cmp esi, ebx
je .end
movzx edx, byte [ecx+esi]
mov [eax+esi], dl
inc esi
jmp .c1
.end:
ret

new: ; ebx=size, eax=ptr, ecx=preserved
mov eax, [hn]
add [hn], ebx
cmp dword [hn], heap + 10000h
jge .of
ret
.of:
puts "heap overflow", 10
jmp exit


