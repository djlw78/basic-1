; example assembly program
; nasm -f elf test.asm && gcc test.o && ./a.out

%include "util.asm"
%include "st.asm"
%define SYM 1
%define NUM 2
%define STR 3
%define CHR 4
%define FUN 5

section .text

global main
main:
puts "BASIC2", 10, 10

mov ecx, sym.print
call hash
mov edx, FUN
mov eax, basicprint
call stput

mov ecx, sym.let
call hash
mov edx, FUN
mov eax, basiclet
call stput

mov ecx, sym.x
call hash
mov edx, NUM
mov eax, 123
call stput

.a:
puts ">"
call read		; return ecx=str
call gnt
cmp edx, 0
je .a
cmp edx, SYM
je .s
; TODO define line
puts "unexpected token "
putr edx
puts 10
jmp .a

.s:
call stget		; populates edx:eax
cmp edx, FUN
je .s2
; TODO call let
puts "unknown symbol", 10
jmp .a
.s2:
call eax			; call the basic command...
jmp .a



basiclet: ; LET sym = exp
puts "LET", 10
; x = 10
call gnt
cmp edx, SYM
je .s
puts "let: missing symbol", 10
ret
.s:
push ebx		; push the symbol
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
pop ebx
call stput		; associate symbol with value...
ret


basicprint: 		; PRINT {exp} [;]
; print x
; print x + 10
.a:
call gne
cmp edx, NUM
je .n
puts 10
ret
.n:
push ecx
mov ecx, buf
call itoa
mov ecx, buf
call write
pop ecx
jmp .a




gne: ; ecx = str, edx=type(2=num,3=str), eax=val
; exp = val [chr exp]
call gnv
cmp edx, 0
jne .b
ret
.b:
push edx		; push type
push eax		; push value
push ecx		; push str
call gnt		; see if next token is chr
cmp edx, CHR
je .c
pop ecx			; pop str
pop eax			; pop val
pop edx			; pop type
ret
.c:
push eax		; push the chr
call gne
cmp edx, 0
jne .d
puts "gne: missing expression", 10
add esp, byte 16
mov edx, 0
ret
.d:
pop ebp			; pop chr
add esp, byte 4		; skip str
pop esi			; pop orig eax
pop edi			; pop orig edx
; ---- evaluate edx:eax = edx:eax ebp edi:esi ----
cmp edi, NUM
je .n
puts "gne: bad expression", 10
mov edx, 0
ret
.n:
cmp edx, NUM
je .n2
puts "gne: bad numeric expression", 10
mov edx, 0
ret
.n2:
mov edx, NUM
cmp ebp, byte '+'
je .nadd
cmp ebp, byte '-'
je .nsub
cmp ebp, byte '='
je .neq
cmp ebp, byte '*'
je .nmul
puts "gne: bad numeric operator", 10
mov edx, 0
ret
.nadd:
add eax, esi
ret
.nsub:
sub esi, eax
mov eax, esi
ret
.neq:
; could use a boolean type...
cmp eax, esi
je .neqe
mov eax, 0
ret
.neqe:
mov eax, 1
ret
.nmul:
imul eax, esi
ret


gnv: ; ecx=str, edx=type(2=num,3=str) eax=value
; val = num | str | sym | (exp)
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
call stget	; might be function...
.end:
ret


gnt: ; ecx = str, edx=type(1=sym,2=num,3=str,4=chr), eax=val, ebx=sym
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
ret
.sp:
inc ecx
jmp gnt
.str:
puts "gnt: str", 10
;TODO
mov edx,3
ret
.dig:
puts "gnt: dig",10
call atoi
mov edx, NUM
ret
.let:
puts "gnt: let", 10
call hash
mov edx, SYM
ret
.chr:
puts "gnt: chr", 10
inc ecx
mov edx, CHR
ret

section .data
sym:
.print:
db "print",0
.let:
db "let",0
.x:
db "x",0

section .bss

buf: resb 256
