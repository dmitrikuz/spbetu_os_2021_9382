CODE SEGMENT
	ASSUME cs:CODE, ds:NOTHING, ES:NOTHING, SS:NOTHING

START: JMP MAIN

o_adress db 13,10,'o1 segmen adress:       ',13,10,'$'

MYPRINT PROC NEAR
	push ax
    mov ah,09H
    int 21H
	pop ax
    ret
MYPRINT ENDP
;-----------------------------------------------------
TETR_TO_HEX PROC NEAR
    and al,0Fh
    cmp al,09
    jbe NEXT
    add al,07
NEXT:
	add al,30h ; КОД НУЛЯ
    ret
TETR_TO_HEX ENDP
;-----------------------------------------------------
BYTE_TO_HEX PROC NEAR
	;БАЙТ В al ПЕРЕВОДИТСЯ В ДВА СИМВОЛА В ШЕСТ. СС ax
    push CX
    mov ah,al
    call TETR_TO_HEX
    XCHG al,ah
    mov CL,4
    SHR al,CL
    call TETR_TO_HEX ;al - СТАРШАЯ
    pop CX 			 ;ah - МЛАДШАЯ ЦИФРА
    ret
BYTE_TO_HEX ENDP
;-----------------------------------------------------
WRD_TO_HEX PROC NEAR
; ПЕРЕВОД В 16СС 16ТИ РАЗРЯДНОГО ЧИСЛА
; ax - ЧИСЛО, di - АДРЕС ПОСЛЕДНЕГО СИМВОЛА
    push bx
    mov BH,ah
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    dec di
    mov al,BH
    call BYTE_TO_HEX
    mov [di],ah
    dec di
    mov [di],al
    pop bx
    ret
WRD_TO_HEX ENDP
;-----------------------------------------------------
MAIN PROC FAR
	push ax
	push dx
	push di
	push ds

	mov ax, cs
	mov ds, ax
	mov bx, OFFSET o_adress
	add bx, 24
	mov di, bx
	mov ax, cs
	call WRD_TO_HEX
	lea dx, o_adress
	call MYPRINT

	pop ds
	pop di
	pop dx
	pop ax
	retf
MAIN ENDP
CODE ENDS
END
