        ideal
        p386
        jumps
        smart
        locals  @@
        segment CODE
	assume  cs:CODE,ds:CODE
        org     100h
Start:  jmp     Inst

XLAT_TBL:
include "kb_xlat.asm"

proc    NewCA
	xor     eax,eax
	in      al,dx
	mov	al,[byte ptr cs:XLAT_TBL+eax]
	iret
	endp

Inst:
	mov	dx,offset Intro
	call	FastEx
	mov	ax,35CAh
	int	21h
        mov     dx,offset NewCA
	cmp	bx,dx
	je	Alrdy
	mov     ax,25CAh
        int     21h
	mov	dx,offset InsMsg
	call	FastEx
	mov     dx,offset Inst
        int     27h
Alrdy:	mov	dx,offset AlrMsg
FastEx:	mov	ah,9
	int	21h
	ret

Intro	db	'Keyboard Corrector (C)1996 FRIENDS Software',13,10,'$'
InsMsg	db	'Installed. Type DOOM2 to continue',13,10,'$'
AlrMsg	db	'Already installed. Type CTRL-ALT-DEL to uninstall',13,10,'$'

	ends    CODE
        end     Start


