TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:TESTPC
 ORG 100H
 .386
START: JMP BEGIN
; Данные
availablemem db 'Memory for program: ', '$'
extendedmem db 'Extended memory: ', '$'
divisor dd 10
mcbtype db '----MCB Type:    ',13, 10, '$'
pspadress db 'PSP Adress/Extra data:    ', '$'
memsize db ' Memory size: ', '$'
data db 'Data:',  '$'
memfail db 'Memory error', 13, 10, '$'
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
WRD_TO_DEC PROC near
 	
			xor cx, cx
divide:
			xor 	dx, dx
			div     divisor
			push    dx
			inc     cx
			cmp 	ax, 0
			jne     divide

print:
			pop     dx
			add     dl, '0'
			mov 	al, dl
			int 	29h
			loop    print
	
			mov al, 13
			int 29h
			mov al, 10
			int 29h
			ret
WRD_TO_DEC ENDP

PRINT_MEM PROC NEAR
			
			mov DX, offset availablemem
			call WRITE_MSG
			
			
			
			mov bx,0Ah
			mov ah,4ah
			int 21h
			
			jc carry
			mov ah, 48h
			mov bx, 1000h
			int 21h
			
			
			
	
			mov eax, ebx 
			mov ebx, 16    ;параграф
			mul ebx
				
			call WRD_TO_DEC
			jmp tothend
			
			carry:
			mov dx, offset memfail
			call WRITE_MSG
			tothend:
						
			ret
PRINT_MEM ENDP
;-----------------------------------------

PRINT_EXTENDED PROC NEAR

			mov DX, offset extendedmem
			call WRITE_MSG

			mov al, 30h
			out 70h, al
			in al, 71h
			mov bl,al
			mov al,31h
			out 70h,al
			in al, 71h
			xor dx,dx
		
			mov ah, al
			mov al, bl
			call WRD_TO_DEC

			ret

PRINT_EXTENDED ENDP

PRINT_CURRENT_MCB PROC NEAR
		
		mov al, es:[00h]
		xor ah, ah
		mov di, offset mcbtype
		add di, 16
		call WRD_TO_HEX
		mov dx, offset mcbtype
		call WRITE_MSG
		
		mov ax, es:[01h]
		mov di, offset pspadress
		add di, 25
		call WRD_TO_HEX
		mov dx, offset pspadress
		call WRITE_MSG
		
		mov dx, offset memsize 
		call WRITE_MSG
		mov ax, es:[03h]
		mov ebx, 16    ;параграф
		mul ebx
		call WRD_TO_DEC
		
		
		mov dx, offset data
		call WRITE_MSG
		mov bx, 0h
print_sym:
		cmp bx, 7h
		jge endthis
		mov al, es:[08h + bx]
		int 29h
		inc bx
		jmp print_sym		
endthis:		
		mov al, 13
		int 29h
		mov al, 10
		int 29h
		ret
	
PRINT_CURRENT_MCB ENDP

PRINT_MCBS PROC NEAR
		mov ah,52h
		int 21h
		mov ax,es:[bx - 2]
		mov es,ax
	print_mcb:
		call PRINT_CURRENT_MCB
		mov bh,es:[0h]
		cmp bh, 05Ah
		je exit
		mov ax,es:[3h]
		inc ax
		mov bx,es
		add ax,bx
		mov es,ax
		 
		jmp print_mcb
	exit:
		ret

PRINT_MCBS ENDP
 ;КОД
BEGIN:
			call PRINT_MEM
			call PRINT_EXTENDED
			call PRINT_MCBS
			xor AL,AL
			mov AH,4Ch
			int 21H
TESTPC ENDS
 END START
			
		