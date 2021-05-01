
ASTACK     SEGMENT 		STACK
          DW 512 DUP (?)   
ASTACK     ENDS

DATA SEGMENT
block_destryoed db 'Block destroyed error' , 13, 10, '$'
memory_not_enough db 'Memory not enough error', 13, 10, '$'
invalid_adress_of_block db 'Invalid adress of block error', 13, 10, '$'
ctrlbreak_finish db 13, 10,'Program exitde with ctrlbreak', 13, 10, '$'
ok_finish db 13, 10,'Program executed sucessfully with code    ', 13, 10, '$'
bad_finish db 'Program execution failed with code    ', 13, 10, '$'
prog_name db 'LB2.COM', 0
epb dw 0 ;сегментный адрес среды
    dd 0 ;сегмент и смещение командной строки
    dd 0 ;сегмент и смещение FCB 
    dd 0 ;сегмент и смещение FCB 
DATA ENDS


CODE SEGMENT
     .386
	 ASSUME CS:CODE, DS:DATA, SS:ASTACK
; Процедуры


WRITE_MSG PROC near
			push ax
			mov AH, 09h
			int 21h
			pop ax
			ret
WRITE_MSG ENDP
;--------------
BYTE_TO_DEC PROC near
;Перевод в 10чную с/с, SI - адрес младшей цифры
			push CX
			push DX
			xor AH,AH
			xor DX,DX
			mov CX,10
loop_bd: 	div CX
			or DL,30h
			mov [SI],DL
			dec SI
			xor DX,DX
			cmp AX,10
			jae loop_bd
			cmp AL,00h
			je end_l
			or AL,30h
			mov [SI],AL
end_l: 		pop DX
			pop CX
			ret
BYTE_TO_DEC ENDP
;------------------------------- 

SET_EPB PROC NEAR
		    mov ax,es:[2ch]
		    mov epb,ax
		    mov epb+2,es
		    mov epb+4,80h
		    ret
SET_EPB ENDP

PROCESS_EXECUTION PROC NEAR
			push ax
			mov ah, 4dh
			int 21h
			cmp ah, 0
			je codezero
			cmp ah, 1
			je break
			
			codezero:
			mov SI, OFFSET ok_finish
			add SI, 43
			call BYTE_TO_DEC
			mov DX, OFFSET ok_finish
			call WRITE_MSG	
			jmp _end
			
			break:
			lea dx, ctrlbreak_finish
			call WRITE_MSG
			_end:
			pop ax
			ret
PROCESS_EXECUTION ENDP
;-------------------------------
PROCESS_FAILURE PROC NEAR
			push ax
		
			mov SI, OFFSET bad_finish
			add SI, 37
			call BYTE_TO_DEC
			mov DX, OFFSET bad_finish
			call WRITE_MSG	
			pop ax
			ret
PROCESS_FAILURE ENDP
;-------------------------------
START_PROGRAM PROC NEAR
		
	
			jmp start
			keep_ss dw 0
			keep_sp dw 0
			keep_ds dw 0
			
			start:
			;выделение памяти под программу и переход к обработке возможных ошибок
			push bx
			mov bx, 800
			mov ah,4ah
			int 21h
			jc carry
			
			pop bx
			
			;сохранение регистров
			mov keep_ss, ss
			mov keep_sp, sp
			mov keep_ds, ds

			;загружаем путь к файлу в DS:DX
			mov dx, offset prog_name 
		
			;устанавливаем параметры 
			call SET_EPB 
			mov bx, offset epb	
			
			;вызов программы
			mov ax,4B00h 
			int 21h
			jnc executed
			
			call PROCESS_FAILURE
			jmp restore
			
			executed:
			call PROCESS_EXECUTION
			;восстановление регистров
			restore:
			mov ss,keep_ss
			mov sp,keep_sp
			mov ds, keep_ds
			
			jmp exitfromhere
			
			;обработка ошибок
			carry:
			cmp ax, 7
			je destroyed
			cmp ax, 8
			je not_enough
			cmp ax, 9
			je invalid_adress
			jmp exitfromhere
			destroyed:
			mov dx, offset block_destryoed
			jmp exitfromhere
			not_enough:
			mov dx, offset memory_not_enough
			jmp exitfromhere
			invalid_adress:
			mov dx, offset invalid_adress_of_block
		
			exitfromhere:
			ret
START_PROGRAM ENDP

MAIN 		PROC FAR

			mov ax,DATA
			mov ds,ax
			call START_PROGRAM
			mov ah, 4ch
			int 21h
MAIN 	ENDP
CODE ENDS
     END MAIN
			
		
			
		
			
		