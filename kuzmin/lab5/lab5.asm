ASTACK     SEGMENT 		STACK
          DW 512 DUP (?)   
ASTACK     ENDS

DATA SEGMENT
resident_set db 'Interruption is already loaded' , 13, 10, '$'
resident_not_set db 'Interruption loaded succesfully', 13, 10, '$'
unload db 'Interruption unloaded', 13, 10, '$'
param db ' /un'
psp dw 0
DATA ENDS
CODE SEGMENT
     .386
	 ASSUME CS:CODE, DS:DATA, SS:ASTACK
; Процедуры
m1:
ROUT PROC FAR
			jmp start
			keep_ip dw 0
			keep_cs dw 0
			sign dw 0A35Fh		
			keep_sp dw 0
			start_adress dw 0
			keep_ss dw 0
			keep_ax dw 0
			int9_vect dd 0
			REQ_KEY db 2h				
			new_stack db 64 dup (?)
			
			start:
			mov keep_sp, sp
			mov keep_ss, ss
			mov keep_ax, ax
			mov sp, offset new_stack
			add sp, 64
			mov ax, seg new_stack
			mov ss, ax 
		
			
			push ax
			push cx
			push ds
			push es
			
			
			in al, 60h
			cmp al, REQ_KEY
			je do_req 

			pop es
			pop ds
			pop cx
			pop ax
			mov ss, keep_ss
			mov sp, keep_sp
			mov ax, keep_ax
			
			jmp cs:[int9_vect]
				
			do_req:
			push ax
			in al, 61h   
			mov ah, al    
			or al, 80h    
			out 61h, al    
			xchg ah, al    
			out 61h, al    
			mov al, 20h     
			out 20h, al 
			pop ax
						
			;запись символа 'D' вместо '1' 
			write:
			mov ah, 05h
			mov cl, 'D'
			int 16h 
			xor ch, ch
			or al, al 
			jnz skip 
			jmp exrout
			
			skip: 
			mov es, ax	
			mov al, es:[41AH]	
			mov es:[41CH], al
			jmp write
			
			exrout:
			pop es
			pop ds
			pop cx
			pop ax
			mov ss, keep_ss
			mov sp, keep_sp
			mov ax, keep_ax
			iret
ROUT ENDP 
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
			MOV AL, 09h
			INT 21H
			pop ax
			pop dx
			POP DS
			STI
			RET
RESTORE_VECTOR ENDP
end_rout:
WRITE_MSG PROC near
			push ax
			mov AH, 09h
			int 21h
			pop ax
			ret
WRITE_MSG ENDP

;-----------------------------
SET_INTERRUPT PROC NEAR	


			mov ah, 35h
			mov al, 09h
			int 21h
			mov keep_cs, es
			mov keep_ip, bx
			mov word ptr int9_vect[02h], es
			mov word ptr int9_vect, bx

			
			PUSH DS
			PUSH AX
			PUSH DX
			MOV DX, OFFSET ROUT
			MOV AX, SEG ROUT

			MOV DS, AX 
			MOV AH, 25H

			MOV AL, 09h
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
			
			mov DX,offset end_rout
			mov cl,4h
			shr dx,cl
			inc dx
			mov ax, cs
			sub ax, psp
			add dx,ax
			xor ax,ax
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
			MOV AL, 09h
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

			mov ax,es:start_adress
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
			mov es, start_adress
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
			mov start_adress, es
			call CHECK_VECTOR
			mov ah, 4ch
			int 21h
MAIN 	ENDP
CODE ENDS
     END MAIN
			
		