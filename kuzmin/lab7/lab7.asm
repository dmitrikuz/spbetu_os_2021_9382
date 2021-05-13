ASTACK     SEGMENT 		STACK
          DW 200 DUP (?)   
ASTACK     ENDS
DATA SEGMENT
overlay_loaded db 'Overlay succesfully loaded' ,13, 10, '$'
overlay_name1 db 'overlay1.ovl', 0
overlay_name2 db 'overlay2.ovl', 0
overlay_name_addr dw 0
setflag db 1
mem_error db 'Memory error. Code    ', 13, 10, '$'
load_error db 'Overlay loading error. Code   ' , 13, 10, '$'
size_detect_error db 'Unable to detect size of overlay', 13, 10, '$'
epb dw 0
	dw 0
dta db 43 dup(0)  
overlay_entry_point   dd  0
keep_sp dw 0
keep_ss dw 0
DATA ENDS
CODE SEGMENT
     .386
	 ASSUME CS:CODE, DS:DATA, SS:ASTACK
; Процедуры
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:       add AL,30h
            ret			
TETR_TO_HEX ENDP
;------------------------------- 
WRITE_MSG PROC near
			mov AH, 09h
			int 21h
			ret
WRITE_MSG ENDP
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

FREE_MEMORY PROC NEAR
			push ax
			push bx
			push si
			push dx
			mov bx, offset end_point
			mov ax,es
			sub bx,ax
			mov ax,bx
			shr bx,4
			add bx, 1
			mov ah,4ah
			int 21h
			jc  error_message2
			jmp exit_free
			error_message2:
			mov si, offset mem_error
			add si, 19
			call BYTE_TO_DEC
			mov dx, offset mem_error
			call WRITE_MSG
			exit_free:
			pop dx
			pop si
			pop bx
			pop ax
			ret
FREE_MEMORY ENDP
;-------------------------------
SET_OVERLAY PROC NEAR
			mov ah,1Ah
			mov dx, offset dta
			int 21h
			
			mov ah,4Eh
			mov dx, overlay_name_addr
			mov cx,0
			int 21h
			jc error_message1
			
			mov si, offset dta
			mov bx, word ptr[si + 1ah]	
			mov ax, word ptr[si + 1ch]	
			shr bx, 4 
			shl ax, 12
			add bx, ax
			add bx, 1
			mov ah,48h
			int 21h						      
	 
			mov epb,ax         
			mov epb + 2,ax       					  
			mov word ptr overlay_entry_point + 2,ax
			jmp exit_set
			
			error_message1:
			mov dx, offset size_detect_error
			call WRITE_MSG
			mov setflag, 0
			exit_set:
			ret
SET_OVERLAY ENDP
RUN_OVERLAY PROC NEAR
			mov     ax,ds          
			mov     es,ax
	 
			mov     dx, overlay_name_addr
			mov     bx,offset epb  
			mov     ax,4b03h       
			int     21h    
			
			
			mov dx, offset overlay_loaded
			call WRITE_MSG
	 
			push    ds              
			call    overlay_entry_point 
			pop     ds 
			mov es, epb
			mov ah, 49h
			int 21h
			ret
RUN_OVERLAY ENDP
LOAD_OVERLAY PROC NEAR
		
					
			push ax
			push bx
			push dx
			push es
			
			mov     keep_ss,ss      
			mov     keep_sp,sp
			
				
			call SET_OVERLAY
			cmp setflag, 0
			je skiprun
			call RUN_OVERLAY
			
			skiprun:
			mov setflag, 1
			mov     ss,keep_ss       
			mov     sp,keep_sp
			
			pop es
			pop dx
			pop bx
			pop ax
			ret
LOAD_OVERLAY ENDP

MAIN 		PROC FAR

			mov ax,DATA
			mov ds,ax
			call FREE_MEMORY		
			mov overlay_name_addr, offset overlay_name1
			call LOAD_OVERLAY
			mov overlay_name_addr, offset overlay_name2
			call LOAD_OVERLAY
			
			mov ah, 4ch
			int 21h
			end_point:
MAIN 	ENDP
CODE ENDS
     END MAIN
