; simple basic interpreter for linux
; nasm -f elf basic.asm && ld -s -nostartfiles basic.o -o basic && ./basic

global _start
section .text		;(read only) start of code

_start: xor ebp,ebp
xor eax,eax
xor ebx,ebx
xor ecx,ecx
xor edx,edx
xor edi,edi
mov esi, m1
call pss		;will it work?

promptstart: ;-------------------prompt routine-------
mov esi,promptstr
call pss
mov esi,comstr
call inputstringsub  		;returns EBX=len
				;removes leading spaces needed
cmp ebx,2
jl promptstart

mov esi, comstr			;make sure ESI points to comstr
mov eax, [pmf]
test eax,eax
jz end_pm
rdtsc			;get cc count
mov [pmc],eax		;save it
end_pm:

push dword nextcs		;point to return address
				;check!!!!

run_enter:			;where run sub joins us
call mna
test edx,edx
je near p_next			;--check label!!!!!
xor eax,eax
mov ax,[esi]    		;get first 4 letter of comstr

cmp eax,'pr'			;urgent commands
je near iprintsub
cmp eax,'le'
je near iletsub
cmp eax,'ne'
je near inext
cmp eax,'go'
je near igoto
cmp eax,'if'
je near iif
cmp eax,'th'
je near ithen

cmp eax,'fo'
je near ifor
cmp eax,'in'			;not so urgent commands
je near iinput
cmp eax,'li'
je near i_list
cmp eax,'va'
je near ivalsub
cmp eax,'ru'
je near irunsub
cmp eax,'pm'
je near i_pm
cmp eax,'ex'
je near iendsub
cmp eax,'qu'
je near iendsub

cmp al,'1'
jl p_next
cmp al,'9'
jle near add_a_line
p_next:

pop ebx				;rebalance stack
mov dword [runf],0		;clear the run flag
mov esi,m8			;error msg
call pss

pluto:
mov dword [runf],0		;clear run flag
cmp dword [pmf],0		;is perunformance monitoring on?
jz near promptstart		;nope
;-------go back to start if mistake---------
rdtsc
sub eax,[pmc]			;works out clocks for command
mov esi,m11
mov [pmc],eax			;saves this
call pss			;prints 'that took '
mov eax,[pmc]
mov esi,argstr
call ces
call psslen			;prints clocks taken
mov esi,m12
call pss			;prints ' clock cycles'
jmp promptstart

nextcs:				;entry point
cmp dword [runf],0		;--replace with mov eax,[runf] : test eax,eax?
jz pluto			;program isnt running

mov eax,[li]
call scan_g			;will return EDX=0 if fail, =1 if success
goto_enter:
test edx,edx
jz pluto			;display pm info, clear run flag

mov [li],ecx
mov esi,ebx			;ESI points to next command string
jmp end_pm
;--------------end of prompt routine--------

ithen:
add esi,4
jmp run_enter

irunsub:		;starts the RUN process
mov eax,1
call scan_g		;input EAX
			;returns EBX pointing to code or DX=0 fail
			;DI points to clut
test edx,edx
jz irun_end		;failed to find a line
mov [li],ecx		;save the basic line number
mov dword [runf],1	;set the run flag
mov esi,ebx		;esi points to command string
jmp run_enter
irun_end:
mov esi,m7
call pss		;says it cant find a line to run
ret

scan_e:			;input EAX line to find
mov edi,clut-4
xor edx,edx
venus:
add edi,4
cmp edi,clut+40
jge scan_fail		;fail, DX=0
cmp eax,[edi]
jne venus		;not the required line
mov ecx,eax
jmp jupiter		;otherwise EDI is clut offset, EAX basic line

scan_g:			;input EAX, line to get closest but greater than
mov ebx,clut-4
mov ecx,30000		;max line number
xor ebp,ebp

saturn:
cmp ebx,clut+40
jge scan_g_end		;scanned all
mov edx,[ebx]		;get the line number from clut
add ebx,4		;point to next clut value
test edx,edx		;if its 0
je saturn
cmp eax,edx		;IF EAX<=EDX then discard
jae saturn
cmp edx,ecx		;IF EDX>=ECX then discard
jae saturn
inc ebp
mov ecx,edx		;save the line number in ECX
mov edi,ebx		;save the offset in EDI, remember its 4 too high
jmp short saturn

scan_g_end:
xor edx,edx		;no success
test ebp,ebp		;will be different if it found something
jz scan_fail		;ie just return, with EDX=0
sub edi,4		;ECX=line number, EDI clut offset
 
jupiter:		;sub to convert clut offset to code offset
			;input EDI=clut offset, ECX=line number
mov ebx,edi
sub ebx,clut		;EBX=0,4,8,12...
mov edx,1		;--perhaps replace with inc?
shl ebx,4		;EBX=0,64,128,192..multiplies by 16
add ebx,code		;EBX points to code
			;EDI points to clut location
			;ECX is the basic line number
scan_fail:
ret			;return

iif:			;IF (expression<>0) ...
inc esi
inc esi
call gna
test dl,2
jz iif_end
test eax,eax
jz iif_end
jmp run_enter		;ESI should point to whatevers after the expression
iif_end:
ret

igoto:
call gna
test dl,2
jz igoto_end
pop edx
call scan_e
jmp goto_enter
igoto_end:
xor edx,edx
mov [runf],edx
ret

i_list:			;hopefully a list sub
mov eax,1
miranda:
call scan_g		;returns EBX, EDI and ECX
test edx,edx
je i_list_nomore
push ecx
push ebx
mov eax,ecx
mov esi, argstr
call ces
call psslen		;displays the basic line number

xor ebx,ebx		;prints a space
mov edi,space
inc ebx
call psslen

pop esi			;EDI is offset to string
call iss2		;returns len in EBX, ESI preserved
inc ebx			;to include the line feed
mov edi,esi
call psslen

pop eax
jmp short miranda
i_list_nomore: ret

add_a_line:
call gna		;returns line number as EAX
push eax		;save line number

call scan_e		;will return DX=1 f the line already exists
push ebx		;save code ptr
push edi		;save clut ptr
push edx		;save success

call mna		;EDX=success of mna
			;ESI=points to next arg
pop ecx			;ECX=success of scan_e
pop edi			;restore EDI=clut ptr
pop ebx			;restore EBX=code ptr
pop eax			;EAX=basic line number

cmp edx,1		;--better to use test on 8 bit operands, 1 in reg
jne clearline		;NE=either nothing or delete

cmp ecx,1
je neptune		;E=change line otherwise add one

newline:	;---------------add a new line in clut--------------
push esi		;save source command string
push eax		;save line number

xor eax,eax		;line to find=0
call scan_e		;this will get the next free line
			;returns EBX=code ptr dest,EDI=clut offset
cmp edx,1
jne aal_fail_pop2	;rebalance stack and leave if no more free lines
			;error message too
pop eax			;restore line number
pop esi			;restore source offset
mov [edi],eax		;stores in clut

neptune:	;----------copys rest of comstr to code---------------
			;EBX is destination
			;ESI is source

mov ecx,10		;end char= 0 or lf
call copystrsub		;should move it into the code stack, and terminate
ret
clearline:
test ecx,ecx
jz clear_end		;could replace with _CMOVEQ_
xor edx,edx
mov [edi],edx
clear_end: ret

aal_fail_pop2:
pop ebx
pop eax
mov esi,m6
jmp pss			;pss will return for us

iendsub:
xor ebx,ebx
mov eax,1
int 80h			;linux way to exit program
jmp short iendsub

inputstringsub:		;input string dest in ESI
push esi
mov edx,64		;max length (i think)
mov ecx,esi		;pointer to destination
xor ebx,ebx
mov eax,3
int 80h			;input via stdin (i think)
pop esi			;esi points to start

iss2:			;find string len as ESI
xor ebx,ebx
mov al,[esi]		;first letter
cmp al,10
je iss_end		;no string there?

iss3:			;this loop could be unrolled using ror
inc ebx			;otherwise another letter
mov al,[esi+ebx]	;get next letter
cmp al,10		;check it
jne iss3
iss_end: ret		;len in EBX? ESI preserved

psslen:			;input EDI, len in EBX
mov edx,ebx
mov ecx,edi
mov eax,4
mov ebx,1
int 80h
ret

printstringsub:		;si is string offset (MUST have len in dword [ESI])
pss:
mov ecx,esi
mov eax,4
mov edx,[esi]
add ecx,4
mov ebx,1
int 80h
ret

copystrsub:		;input ESI source offset, EBX destination offset
			;CL=delimiter 1, CH = delimiter 2
xor edi,edi
css1:
mov al, [esi]
cmp al,cl		;check for first delimiter
je end_copy
cmp al, ch		;check for second delimiter
je end_copy
mov [ebx+edi],al	;copy charactor
inc esi
inc edi
jmp short css1
end_copy:		;jump here once string is copied
mov byte [ebx+edi],10	;terminate with a line feed
dec edi
ret			;ESI points to next arg, EDI=len

mna:	;MOVE to NEXT argument input ESI
mov eax,[esi]		;get first 4 chars
xor edx,edx		;clear success
and eax,0xffff
test eax,0xff
jz mna_end		;if first char was 0 then leave (with EDX=0)
cmp al,10
je mna_end		;end of string

inc esi
cmp al,32
je mna			;more spaces then go back to start

dec esi			;ESI points to first letter AL
inc edx			;EDX=1
mna_end: ret		;with AL=first letter, AH=second letter

; ///////////////////////////////////////////////////////////////
gna: ; /// ;input ESI string offset /////////////////////////////
;/////// ;out argstr, EDX = 0=fail, bit0=str, bit1=eax, bit2=ivar
;////////////////////////////////////////////////////////////////
call mna
test edx,edx
jz mna_end

cmp al, 34		;start scanning for data types
je near str_k		;jump to string const if "

cmp al,'9'
jg gna_dt3
cmp al,'0'
jge near num_c		;jump to num const if 0>9

gna_dt3:		;check for resident integer variables
cmp al,'i'
jne gna_dt4
cmp ah,'a'
jl gna_dt4
cmp ah,'f'
jle near num_ivar	;jmp to int var if ia-if

gna_dt4:
cmp al,'('
je ee

inc esi
jmp short gna		;no data found, get next char and scan again

;===================================================================

ee:			;the expression evaluator
inc esi
call gna		;will return the first argument
test edx,2		;is it numeric?
jz ee_fail_first
push eax		;otherwise we need to push the value
			;next we need the operator:  +-*\/%=

call mna		;operator returned in AL
test edx,edx
jz ee_fail_op
push eax		;save operator (more effcient to save it as a dword)

inc si			;assumes operator is 1 char long

call gna
test edx,2
jz ee_fail_second	;otherwise the second parameter is EAX

;ESI points to next arg - should be ')' or leading spaces
push eax
call mna
cmp al,')'
jnz ee_fail_close

pop ecx			;second param in ECX
xor edx,edx
pop ebx			;operator
pop eax			;first param in EAX
inc esi			;should point to next arg
mov dl,2		;numeric return
cmp bl,'+'
je ee_add
cmp bl,'-'
je ee_sub
cmp bl,'='
je ee_equ
cmp bl,'*'
je ee_mul
cmp bl,'%'
je ee_mod
cmp bl,'/'
je ee_div
cmp bl,'\'
je ee_div
cmp bl,'&'
je ee_and
jmp short ee_fail_first	;if it wasnt a valid operator

ee_fail_close: pop eax
ee_fail_second: pop eax
ee_fail_op: pop eax
ee_fail_first: xor edx,edx
push esi
mov esi,m3
call pss
pop esi
ret			;nice error message first?

ee_add: add eax,ecx
ret
ee_sub: sub eax,ecx
ret
ee_equ: cmp eax,ecx
setz al
and eax,0xff
ret
ee_mul: mul ecx		;64 bit result - EDX:EAX, doesnt return EDX
xor edx,edx
mov dl,2
ret

ee_mod: test ecx,ecx
jz ee_divfail
xor edx,edx	;64-bit input EDX:EAX, need 64 bit vars
div ecx
xor eax,eax
mov al,2
xchg eax,edx	;move the remainder into eax
ee_divfail: ret

ee_div: test ecx,ecx
jz ee_divfail
xor edx,edx
div ecx
xor edx,edx
mov dl,2
ret

ee_and:
test ecx,ecx
setnz bl
test eax,eax
setnz al
and al,bl
and eax,0xff
ret
;===================================================================

str_k:
inc esi
xor ebx,ebx
mov edi,esi
strk1:
mov al,[esi+ebx]
test al,al
je strk2
cmp al,34
je strk2
cmp al,10
je strk2
inc ebx
jmp strk1
strk2:			;EBX=len
add esi,ebx
inc esi			;leaves EDI=offset EBX=len ESI=point to next arg
xor edx,edx
inc edx			;string
ret

num_ivar:		;num ivar **********************
add esi,2		;ESI goes up twice to point to next arg
xor ebx,ebx
sub ah,'a'
mov bl, ah
xor edx,edx
lea ebp,[ebx*4+ivars]	;EBP is address of var in memory
mov eax,[ebp]		;get the var into eax
mov dl,110b		;data type=EAX and num-var
ret 			;ESI points to next arg, EAX is num, EBP is ofset of var

num_c: 			;num-const *************************
call gns		;returns ECX as valued string
xor edx,edx
mov eax,ecx
mov dl,2		;number in EAX
ret
; //////////////////////////////////////////////////////////////////

iletsub:   		;---------LET <num-var> <numeric> -----------
call gna
test edx,4
jz ils_end		;if the ivar bit was 0 then end
push ebp		;stores the offset of the destination
call gna
pop ebx
test dx,2
jz ils_end		;source wasnt numeric
mov dword [ebx],eax	;store source into destination
ils_end: ret

iprintsub: ;------ PRINT {<string>|<numeric>} -------------------
call gna		;returns EDI as offset and EBX as len- or just EAX
test dl,dl		;was anything returned?
jz end_ips		;Z=no
test dl,10b		;is it a number returned?
jz ips2			;Z=no

push esi		;its a number, chuck it though ces
mov esi,argstr
call ces		;gets the string at EDI
call psslen		;prints it
pop esi			;restore comstr
jmp short iprintsub	;get next argument

ips2:			;its string
push esi		;saves SI (comstr)
call psslen		;input of psslen compatible with gna output
pop esi			;restores SI pointing to comstr, might not be nessacary
jmp short iprintsub	;get next argument

end_ips:
mov esi,lf
call pss		;prints a line feed
ret

for_end_pop2: pop ebx
for_end_pop1: pop eax
for_end: ret

ifor:	;-----FOR <num-var> <numeric> <numeric> [<numeric>]--------
call gna
test dl,4
jz for_end
push ebp		;save the var offset

call gna
test dl,2
jz for_end_pop1
push eax		;save start value

call gna
test dl,2
jz for_end_pop2
push eax		;save end value

call gna
test dl,2
jnz ifor2
xor eax,eax
inc eax

ifor2:			;EAX= step value (1 by default)
pop edx			;EDX=end value
pop ecx			;ECX=start value
pop ebp			;EBP=var offset
pop ebx			;EBX=return address
mov edi,[li]		;EDI=value for scan_g
mov [ebp],ecx		;set var to start value
jmp short inext_push

inext:		;----------NEXT--------------------
pop ebx		;return address
pop edi		;value for scan_g
pop eax		;step
pop edx		;end value
pop ebp		;offset

cmp [ebp],edx
je inext_end
add [ebp],eax	;next value
mov [li],edi	;go back to line after for

inext_push:
push ebp	;save offset
push edx	;save end value
push eax	;save step
push edi	;save target
inext_end:
jmp ebx		;should be =EBX

ivalsub:	;---------VAL [<numeric>] -----------------
call gna		;would return argstr and number and dx=3
test edx,2
jnz mars		;jump if argument was specified (EAX)

mov esi,qm
call pss
mov esi, argstr2	;string buffer 2
call inputstringsub
mov esi, argstr2
call gna
test edx,2
jz near scan_fail

mars:			;input EAX
mov esi, argstr
call ces	;returns string in ESI
call psslen
mov esi,lf
call pss
ret

errormsg:		;input ESI, bit of redundant subroutine
call pss
mov esi, lf
call pss
ret

iinput:	;----------------INPUT <num-var>---------------
call gna
pop eax
test dl,4		;is it a variable argument?
jz near nextcs		;would be nice to say jz eax
push eax
push ebp		;save offset
mov esi,qm
call pss		;print a question mark
mov esi, argstr
call inputstringsub
mov esi, argstr
call gna
pop ebp			;EBP=ofset of variable
pop ecx			;ECX=return address
test dl,2		;numeric return?
jz near nextcs		;Z=nope
mov [ebp],eax		;load var with numeric
jmp ecx			;return

i_pm: ;------------------PM <numeric> sub----------------------
call gna
mov esi, m2
test edx,2
jz near errormsg

test eax,eax
je pm_off		;jump if user wants it off

mov esi, m4
call pss		;say 'set on'
rdtsc
mov dword [pmf],1
mov [pmc],eax
ret

pm_off:
mov esi,m5
call pss
mov dword [pmf],0	;set off
ret

gns:			;input ESI pointing to string
xor eax,eax		;clear 10^n column counter
xor ecx,ecx		;clear overall counter

gns1:
mov al,[esi]		;get next digit
sub al,'0'		;remove ascii encoding
jc gns2			;wasnt a number (ascii too low)
cmp al,9		
jg gns2			;wasnt a number (ascii too high)

lea ecx,[ecx*4+ecx]
inc esi			;point to next source digit
add ecx,ecx		;ECX=ECX*10

add ecx,eax		;add digit to ECX
jmp short gns1
gns2: ret		;returns ECX=valued string, ESI point to next arg

ces:			;input EAX (unsigned), ESI dest
xor edx, edx		;clear counter
mov ecx,ces_lut+40
push esi
mov edi, ces_lut	;point to first const

ces0: xor edx,edx
mov ebx, [edi]		;get next const

ces1: inc edx		;one more in 10^n column
sub eax, ebx		;subtract 10^n from source
jc ces2			;stop if negative
inc edx
sub eax,ebx
jc ces2
inc edx
sub eax,ebx
jnc ces1		;keep going of still positive

ces2: add edx,47	;converts edx to ascii
add eax,ebx
add edi,4		;next const
mov [esi],dl		;store char
inc esi			;next dest offset
cmp edi,ecx		;no more digits? (there are 12)
jne ces0		;start next

xor ebx,ebx
mov byte [esi],10	;terminate with lf
pop edi			;EDI=original offset
mov bl,10		;EBX=len = 10
ret			;returns decimal string at ESI+10

;===================read only data====================
lf		dd 1
		dd 10
space		db '    '
promptstr	dd 1
		dd '>'
qm		dd 2
		dd '? '
ces_lut		dd 1000000000
		dd 100000000
		dd 10000000
		dd 1000000
		dd 100000
		dd 10000
		dd 1000
		dd 100
		dd 10
		dd 1
m11		dd 18
		db 'prompt: that took ',0,0
m1		dd 8
		db 'ABASIC',10,10
m8		dd 24
		db 'prompt: no such command',10
m12		dd 14
		db ' clock cycles',10,0,0
m7		dd 24
		db 'irunsub: no lines found',10
m6		dd 20
		db 'no more free lines!',10
m2		dd 18
		db 'ipm: not a numeric',10,0,0
m4		dd 11
		db 'pm: set on',10,0
m5		dd 12
		db 'pm: set off',10
m3		dd 11
		db 'ee: failed',10,0
m33		dd 24
		db 'if: =0 or not a numeric',10

section .data

pmf		dd 0
runf		dd 0
li		dd 0
pmc		dd 0
ivars		times 6 dd 0
comstr		times 64 db 0
argstr		times 64 db 0
argstr2		times 64 db 0
code		times 160 dd 0
clut		times 10 dd 0

