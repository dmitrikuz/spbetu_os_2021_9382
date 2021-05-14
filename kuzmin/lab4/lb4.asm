ASTACK     SEGMENT 		STACK
          DW 256 DUP (?)   
ASTACK     ENDS

DATA SEGMENT
resident_set db 'Interruption is already loaded' , 13, 10, '$'
resident_not_set db 'Interruption is not loaded. Loading...', 13, 10, '$'
unload db 'Interruption unloaded', 13, 10, '$'
param db ' /un'
DATA ENDS
CODE SEGMENT
     .386
	 ASSUME CS:CODE, DS:DATA, SS:ASTACK
; Процедуры
ROUT PROC FAR
			
			jmp start
			sum dw 0
			keep_ip dw 0
			keep_cs dw 0
			sign dw 0A35Fh
			psp dw 0		
			keep_sp dw 0
			keep_ss dw 0
			keep_ax dw 0
			new_stack db 100 dup (?)
			start:
			mov keep_sp, sp
			mov keep_ss, ss
			mov keep_ax, ax
			mov sp, offset start
			mov ax, seg new_stack
			mov ss, ax 
		
			push ax
			push bx
			push cx
			push dx
			
			call getCurs			
			push dx
			
			mov dh, 1
			mov dl, 70
			call setCurs
			
			mov ax, sum
			inc ax
			mov sum, ax
			
			call EAX_TO_DEC
			pop dx
			call setCurs
			
			pop dx
			pop cx
			pop bx
			POP AX
		
			mov ss, keep_ss
			mov sp, keep_sp
			mov ax, keep_ax
			IRET
ROUT ENDP 
WRITE_MSG PROC near
			push ax
			mov AH, 09h
			int 21h
			pop ax
			ret
WRITE_MSG ENDP

EAX_TO_DEC PROC near
 	
			push ebx
			push di
			push dx
			push cx
			push ax
			mov ebx, 0Ah
			mov di, 0
			mov cx, dx
			xor dx, dx
		
divide:
			xor 	dx, dx
			div     ebx
			push    dx
			inc     di
			cmp 	ax, 0
			jne     divide

print:
			dec di
			pop dx
			add dl, '0'
			mov al, dl
			
			push dx
			mov dx, cx
			inc dl
			call setCurs
			call outputAL
			pop dx
			inc cl
			
			cmp di, 0
			jg print
			pop ax
			pop cx
			pop dx
			pop di
			pop ebx
			ret
EAX_TO_DEC ENDP
;------------------------------- 

outputAL proc
			push ax
			push bx
			push cx
			mov ah,09h
			mov bh, 0h
			mov cx,1
			int 10h 
			pop cx
			pop bx
			pop ax
			ret 
outputAL ENDP
;----------------------
setCurs proc
			push ax
			push bx
			mov ah,02h
			mov bh,0
			int 10h
			pop bx
			pop ax
			ret
			
setCurs ENDP	
;----------------------
getCurs proc
			push ax
			push bx
			mov ah,03h
			mov bh,0
			int 10h 
			pop bx
			pop ax
			ret
			
getCurs ENDP
;----------------------
RESTORE_VECTOR PROC NEAR

			CLI
			PUSH DS
			push dx
			push ax
			MOV DX, es:keep_ip
			MOV AX, es:keep_cs
			MOV DS, AX
			MOV AH, 25H
			MOV AL, 1CH
			INT 21H
			pop ax
			pop dx
			POP DS
			STI
			RET
RESTORE_VECTOR ENDP
end_rout:
;-----------------------------

SET_INTERRUPT PROC NEAR	


			mov ah, 35h
			mov al, 1ch
			int 21h
			mov keep_cs, es
			mov keep_ip, bx
			
			PUSH DS
			PUSH AX
			PUSH DX
			MOV DX, OFFSET ROUT
			MOV AX, SEG ROUT

			MOV DS, AX 
			MOV AH, 25H

			MOV AL, 1CH 
			INT 21H
			
			POP DX
			POP AX
			POP DS
					
			
			RET
SET_INTERRUPT ENDP

LOAD_TO_RESIDENT PROC NEAR

			push ax
			push bx
			push dx
			push cx
			
			mov dx, offset end_rout
			mov ax, cs
			add dx, ax
			shr dx,4h
			add dx, 1Fh
			mov ah,31h
			int 21h
			
			pop cx
			pop dx
			pop bx
			pop ax

			ret

LOAD_TO_RESIDENT ENDP
;------------------
CHECK_VECTOR PROC NEAR
 
			PUSH AX
			PUSH BX
			PUSH ES
			PUSH SI
				
			
			MOV AH, 35H
			MOV AL, 1Ch
			INT 21H	
			
			mov ax, 0A35Fh ;уникальное значение
			cmp ax,es:sign
			jne setres	
			
			call CHECK_PARAM ;если установлено, переход к проверку параметра /un
			jmp endthis
					
			setres:	 ;если прерывание не установлено
			mov dx, offset resident_not_set
			call WRITE_MSG
			call SET_INTERRUPT
			call LOAD_TO_RESIDENT
			
			
			endthis:
			POP SI
			POP ES
			POP BX
			POP AX
			RET
CHECK_VECTOR ENDP

UNLOAD_INTERRUPTION PROC NEAR

			
			call RESTORE_VECTOR

			mov ax,es:psp
			mov es,ax
			
			push es
			mov ax,es:[2ch]    ;среда
			mov es,ax
			mov ah,49h
			int 21h
			pop es
			
			mov ah,49h ;резидентная часть
			int 21h
			ret
UNLOAD_INTERRUPTION ENDP

CHECK_PARAM PROC NEAR
		
			push es
			mov es, psp
			mov cx, 4
			mov di, 81h
			mov si, offset param
			cld
			repe cmpsb
			jne notequal
			pop es
			call UNLOAD_INTERRUPTION
			mov dx, offset unload
			call WRITE_MSG	
			jmp ex
			notequal:
			pop es
			mov dx, offset resident_set
			call WRITE_MSG
			ex:
			ret
CHECK_PARAM ENDP

MAIN 		PROC FAR

			mov ax,DATA
			mov ds,ax
			mov psp, es
			call CHECK_VECTOR
			mov ah, 4ch
			int 21h
MAIN 	ENDP
CODE ENDS
     END MAIN
			
		