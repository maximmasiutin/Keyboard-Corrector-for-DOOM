        ideal
        p386
        jumps
        locals  @@
;-EQUALS----------------

CR       equ     13
LF       equ     10
CRLF     equ     13,10
MaxRetries equ   40000h

FirstPort       equ     1F0h
NumPorts        equ     8

segment CODE use16
        assume  cs:CODE,ds:CODE
        org     100h
Start:  jmp     Init

include "sector.inc"

;-CALL-QEMM-API---------
API:
        db      09Ah            ; Call Far
APIo    dw      ?
APIs    dw      ?
        ret

Ready    db      0
CallbSet db      0
CallbClean db    0
FakeCnt  dw      ?
NumRetries dd    0

proc    ClearCallback near
        mov     [cs:CallbSet],0
        mov     [cs:CallbClean],1
        push    dx
        push    ax
        mov     ax,1A0Ah
        mov     dx,1F0h
        call    API
        inc     dx
        call    API
        pop     ax
        pop     dx
        ret
        endp

;-CALLBACK-FUNCTION-----
proc    CallBack far
        cmp     dx,1F0h
        jb      Exception
        cmp     dx,1F7h
        ja      Exception
        push    ax
        mov     ax,1A0Ah
        call    API
        pop     ax
        cmp     cl,0
        je      @@rb
        cmp     cl,4
        je      @@wb
        cmp     cl,8
        je      @@rw
        cmp     cl,0Ch
        jne     Exception
@@ww:   mov     [cs:NumRetries],0
        cmp     [cs:CallbSet],0
        jz      @@ww_o
        call    ClearCallback
@@ww_o: out     dx,ax
        jmp     @@ok
@@rw:   mov     [cs:NumRetries],0
        cmp     dx,1F0h
        jne     @@rw_o
        cmp     [cs:CallbSet],0
        jz      @@rw_o
        in      ax,dx
        push    bx
        mov     bx,[cs:FakeCnt]
        mov     ax,[cs:bx]
        inc     bx
        inc     bx
        cmp     bx,offset FakeSector+512
        jb      @@NotWhole
        call    ClearCallback
@@NotWhole:
        mov     [cs:FakeCnt],bx
        pop     bx
        xchg    al,ah
        jmp     @@ok
@@rw_o:
        in      ax,dx
        jmp     @@ok

@@wb:   mov     [cs:NumRetries],0
        cmp     dx,1F6h
        jne     @@w_ok
        cmp     al,0A0h
        jne     @@clr_cb
        mov     [cs:Ready],1
        jmp     @@w_out
@@w_ok: cmp     [cs:Ready],0
        jz      @@w_out
        mov     [cs:Ready],0
        cmp     dx,1F7h
        jne     @@clr_cb
        cmp     al,0ECh
        jne     @@clr_cb

;; SET CALLBACK
        mov     [cs:FakeCnt],offset FakeSector
        mov     [cs:CallbSet],1
        push    dx
        push    ax
        mov     ax,1A09h
        mov     dx,1F0h
        call    API
        inc     dx
        call    API
        pop     ax
        pop     dx
        jmp     @@w_out

;; CLEAR CALLBACK
@@clr_cb:
        cmp     [cs:CallbSet],0
        jz      @@w_out
        call    ClearCallback

@@w_out:
        out     dx,al
        jmp     @@ok


@@rb:
        cmp     dx,1F7h
        jne     @@rb_o
        cmp     [cs:CallbSet],0
        jz      @@n_cb
        in      al,dx
        mov     al,58h
        jmp     @@ok
@@n_cb: in      al,dx
        inc     [cs:NumRetries]
        cmp     [cs:NumRetries],MaxRetries
        jb      @@ok
        mov     al,50h
        jmp     @@ok
@@rb_o: mov     [cs:NumRetries],0
        in      al,dx

@@ok:   cmp     [cs:CallbClean],0
        mov     [cs:CallbClean],0
        jnz     @@cc
        push    ax
        mov     ax,1A09h
        call    API
        pop     ax
@@cc:   clc
        retf
        endp

include "except.inc"

Init:
;-GET-QEMM-API-ADDRESS--
        mov     ah,3Fh
        mov     cx,5145h        ; 'QE'
        MOV     dx,4D4Dh        ; 'MM'
        int     67h
        or      ah,ah
        jz      Cont1
        mov     dx,offset Err1
        jmp     FastEx
Cont1:
        mov     [APIs],es
        mov     [APIo],di
;-CHECK-QEMM-STATE------
        mov     ah,0
        call    API
        test    al,1
        jz      Cont2
        mov     dx,offset Err2
        jmp     FastEx
Cont2:
        test    al,2
        jz      Cont3
        mov     dx,offset Err3
        jmp     FastEx
Cont3:
        mov     dx,offset Suc1
        call    FastEx
;-CHECK-PORTS-TRAP------
        mov     cx,NumPorts
        mov     si,offset PortList
Cont6:
        lodsw
        xchg    dx,ax
        mov     bp,dx
        mov     ax,1A08h
        call    API
        or      bl,bl
        jz      Cont5
        mov     dx,offset Err5
        jmp     FastEx
Cont5:
;-TRAP-IDE-PORTS--------
        mov     ax,1A09h
        mov     dx,bp
        call    API
        jnc     Cont4
        mov     dx,offset Err4
        jmp     FastEx
Cont4:
        loop    Cont6
;-SET-CALLBACK-ADDRESS--
        mov     ax,1A07H
        push    cs
        pop     es
        mov     di,offset CallBack
        call    API
        mov     dx,offset Suc2
        call    FastEx
        push    cs
        pop     ds
        push    0
        pop     es
        MoveDM  ds:Old10,es:10h*4
        MoveDM  ds:Old21,es:21h*4
        call    ClearCallback
        mov     dx,offset Init
        int     27h

;-FAST-EXIT-------------
FastEx:
        mov     ah,9
        int     21h
        ret

;-PROGRAM-DATA----------
PortList:
        P = FirstPort
      rept    NumPorts
        dw      P
        P=P+1
      endm
Err1            db      'MGR not installed!',lnend
Err2            db      'MGR is turned off!',lnend
Err3            db      'MGR is in AUTO mode!',lnend
Err4            db      'Trap error!$',lnend
Err5            db      'Trap overload!',lnend
Suc1            db      'MGR is OK Ä $'
Suc2            db      'Emulation installed.',lnend



ends    CODE
        end     Start