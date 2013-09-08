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
cmp edx, SYM
je .s
; TODO define line
puts "syntax error", 10
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

ret



basicprint: ; PRINT {exp} [;]
; print x
; print x + 10
puts "PRINT", 10
call gne
cmp edx, NUM
je .n
ret
.n:
; TODO print number
; print lf
ret




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
puts "missing expression", 10
add esp, byte 16
mov edx, 0
ret
.d:
pop ebp			; pop chr
add esp, byte 4		; skip str
pop esi			; pop orig eax
pop edi			; pop orig edx
; combine edx:eax = edx:eax ebp edi:esi
cmp edx, edi
je .e
puts "expression type mismatch "
putr edx
puts " and "
putr edi
puts 10
mov edx, 0
ret
.e:
; TODO operators
mov edx, NUM
add eax, esi
ret


gnv: ; ecx=str, edx=type(2=num,3=str) eax=value
; val = num | str | sym | (exp)
call gnt
cmp edx, 1
jne .b
call stget	; might be function...
ret
.b:
puts "unexpected value", 10
mov edx, 0
;TODO exp
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
puts "nul", 10
ret
.sp:
puts "sp", 10
inc ecx
jmp gnt
.str:
puts "str", 10
;TODO
mov edx,3
ret
.dig:
puts "dig",10
call atoi
mov edx, NUM
ret
.let:
puts "let", 10
call hash
mov edx, SYM
ret
.chr:
puts "chr", 10
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
