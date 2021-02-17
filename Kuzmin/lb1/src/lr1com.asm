TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; Данные
type1 db 'IBM PC Type: PC', 0DH, 0AH, '$'
type2 db 'IBM PC Type: PC/XT', 0DH, 0AH, '$'
type3 db 'IBM PC Type: AT', 0DH, 0AH, '$'
type4 db 'IBM PC Type: PS2 mod. 30', 0DH, 0AH, '$'
type5 db 'IBM PC Type: PS2 mod. 30/60', 0DH, 0AH, '$'
type6 db 'IBM PC Type: PS2 mod. 60', 0DH, 0AH, '$'
type7 db 'IBM PC Type: PCjr', 0DH, 0AH, '$'
type8 db 'IBM PC Type: PC Convertible', 0DH, 0AH, '$'
notype db 'Unknown type:  ', 0DH, 0AH, '$'
dos_ver_string db 'MS-DOS Version:  .  ', 0DH, 0AH, '$'
oem_string db 'OEM Number:   ', 0DH, 0AH, '$'
user_number_string db 'User serial number:        ', 0DH, 0AH, '$'
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
GET_PC_TYPE PROC near
;Вывод типа IBM PC
			push BX
			mov BX,0F000h
			mov ES,BX
			mov AL,ES:[0FFFEh]
			pop BX
			ret
GET_PC_TYPE ENDP
;--------------------------------
PRINT_PC_TYPE PROC near
			cmp AL, 0FFh
			je type1_found
			cmp AL, 0FEh
			je type2_found
			cmp AL, 0FCh
			je type3_found
			cmp AL, 0FAh
			je type4_found
			cmp AL, 0FCh
			je type5_found
			cmp AL, 0F8h
			je type6_found
			cmp AL, 0FDh
			je type7_found
			cmp AL, 0F9h
			je type8_found
			jmp notype_found
type1_found:
			mov DX, OFFSET type1
			call WRITE_MSG
			ret
type2_found:
			mov DX, OFFSET type2
			call WRITE_MSG
			ret
type3_found:
			mov DX, OFFSET type3
			call WRITE_MSG
			ret
type4_found:
			mov DX, OFFSET type4
			call WRITE_MSG
			ret
type5_found:
			mov DX, OFFSET type5
			call WRITE_MSG
			ret
type6_found:
			mov DX, OFFSET type6
			call WRITE_MSG
			ret
type7_found:
			mov DX, OFFSET type7
			call WRITE_MSG
			ret
type8_found:
			mov DX, OFFSET type8
			call WRITE_MSG
			ret	
notype_found:
			mov DI, offset notype
			call BYTE_TO_HEX
			mov [DI + 13], AX
			mov DX, offset notype
			call WRITE_MSG
			ret			
PRINT_PC_TYPE ENDP
;----------------------------------------
LOAD_INFO PROC near
			mov AH,30h
			int 21h
			ret
LOAD_INFO ENDP
;----------------------------------------
PRINT_MS_DOS_VER PROC near
			;Вывод версий DOS
			mov SI, OFFSET dos_ver_string
			add SI, 16
			call BYTE_TO_DEC
			add SI, 3
			mov AL, AH
			call BYTE_TO_DEC
			mov DX, OFFSET dos_ver_string
			call WRITE_MSG
			;Вывод OEM
			mov SI, OFFSET oem_string
			add SI, 13
			mov AL, BH
			call BYTE_TO_DEC
			mov DX, OFFSET oem_string
			call WRITE_MSG
			;Вывод серийного номера пользователя
			mov DI, OFFSET user_number_string
			add DI, 22
			mov AX, CX
			call WRD_TO_HEX
			mov AL, BL
			call BYTE_TO_HEX
			mov [DI + 4], AX
			mov DX, OFFSET user_number_string
			call WRITE_MSG
			ret
PRINT_MS_DOS_VER ENDP
;-----------------------------------------
; КОД
BEGIN:
			call GET_PC_TYPE
			call PRINT_PC_TYPE
			call LOAD_INFO
			call PRINT_MS_DOS_VER		
;Выход в DOS
			xor AL,AL
			mov AH,4Ch
			int 21H
TESTPC ENDS
 END START ; Конец модуля, start - точка входа
			
		