OVERLAY_SEG SEGMENT
	ASSUME CS:OVERLAY_SEG, DS:NOTHING, SS:NOTHING, ES:NOTHING
MAIN PROC FAR

			push ax
			push dx
			
			mov ax,cs
			mov ds,ax

			mov di, offset seg_adress
			add di, 29
			call WRD_TO_HEX
			mov dx, offset seg_adress
			call WRITE_MSG
			pop dx
			pop ax
			RETF
MAIN ENDP
;-------------------
WRITE_MSG PROC near
		   push AX
		   mov AH,09h
		   int 21h
		   pop AX
		   ret
WRITE_MSG ENDP	
;------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
			push BX
			mov BH, AH
			call BYTE_TO_HEX
			mov [DI], AH
			dec DI
			mov [DI], AL
			dec DI
			mov AL, BH
			call BYTE_TO_HEX
			mov [DI], AH
			dec DI
			mov [DI], AL
			pop BX
			ret
WRD_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа в AX
			push CX
			mov AH,AL
			call TETR_TO_HEX
			xchg AL,AH
			mov CL,4
			shr AL,CL
			call TETR_TO_HEX ; В AL старшая цифра, в AH - младшая
			pop CX
			ret
BYTE_TO_HEX ENDP
;------------------------------- 
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:       add AL,30h
            ret			
TETR_TO_HEX ENDP
;------------------------------- 
seg_adress db 'Overlay 2. Segment adress:   ',13,10,13, 10,'$'
OVERLAY_SEG ENDS
END MAIN
