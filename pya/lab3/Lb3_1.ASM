TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN
; ДАННЫЕ 
n db 0dh, 0ah, '$'
area_size db "size:        ", '$'
SC_SD db "SC/SD: ", '$'
address db "address:      ", '$'
PSP_address db "PSP address:      ", '$'
extended_mem_size db "extended memory size:        bytes", 0dh, 0ah, '$'
available_mem_size db "available memory size:        bytes", 0dh, 0ah, '$' 
MCB_number db "MCB #", '$'
dec_number db "   ", '$'

;ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; байт в AL переводится в два символа шестн. числа в AX
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX ;в AL старшая цифра
 pop CX ;в AH младшая
 ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
 push BX
 mov BH,AH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 dec DI
 mov AL,BH
 call BYTE_TO_HEX
 mov [DI],AH
 dec DI
 mov [DI],AL
 pop BX
 ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/с, SI - адрес поля младшей цифры
 push CX
 push DX
 xor AH,AH
 xor DX,DX
 mov CX,10
loop_bd: 
 div CX
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
end_l: 
 pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
print_string proc near
    mov ah, 09h
    int 21h
    ret
print_string endp

para_to_byte proc
    push ax
    push bx
    push cx
    push dx
    push si
   
	mov bx, 10h
	mul bx
	mov bx, 0ah
	xor cx, cx

div_loop:
	div bx
	push dx
	inc cx
	sub dx, dx
	cmp ax, 0h
	jnz div_loop
   
print_sym:
	pop dx
	add dl, 30h
	mov [si], dl
	inc si
loop print_sym
   
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
ret
para_to_byte endp

print_n proc near
    push ax
    push dx

    mov dx, offset n
    mov ah, 9h
    int 21h

    pop dx
    pop ax
ret
print_n endp

print_available_mem_size proc near
    mov ah, 4ah
    mov bx, 0ffffh
    int 21h
    mov ax, bx
    mov si, offset available_mem_size
    add si, 23
    call para_to_byte    
    mov dx, offset available_mem_size
    call print_string
ret
print_available_mem_size endp

print_extended_mem_size proc near
    mov AL,30h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h ; чтение младшего байта
    mov BL,AL ; размера расширенной памяти
    mov AL,31h ; запись адреса ячейки CMOS
    out 70h,AL
    in AL,71h ; чтение старшего байта
    ; размера расширенной памяти
    mov ah, al
    mov si, offset extended_mem_size
    add si, 22
    call para_to_byte
    mov dx, offset extended_mem_size
    call print_string
ret
print_extended_mem_size endp

print_mcb proc near
    push ax
    push dx
    push si
    push di
    push cx

    mov ax, es;MCB
    mov di, offset address
    add di, 12
    call WRD_TO_HEX
    mov dx, offset address
    call print_string
    mov ax, es:[1] ;PSP
    mov di, offset PSP_address
    add di, 16
    call WRD_TO_HEX
    mov dx, offset PSP_address
    call print_string
    mov ax, es:[3] ;size of para
    mov si, offset area_size
    add si, 6
    call para_to_byte
    mov dx, offset area_size
    call print_string
    mov bx, 8 ;SC SD
    mov dx, offset SC_SD
    call print_string
    mov cx, 7
    print_sc_sd_loop:
        mov dl, es:[bx]
        mov ah, 02h
        int 21h
        inc bx
        loop print_sc_sd_loop

    pop cx
    pop di
    pop si
    pop dx
    pop ax
ret
print_mcb endp

offset_dec proc near
    offset_dec_loop:
        cmp byte ptr [si], ' '
        jne end_offset_dec
        inc si
        jmp offset_dec_loop
    end_offset_dec:
ret
offset_dec endp

print_mcb_list proc near
    push ax
    push bx
    push es
    push dx

    mov ah, 52h
    int 21h
    mov ax, es:[bx-2]
    mov es, ax
    mov cl, 1
    print_list:
        mov dx, offset MCB_number
        call print_string
        mov al, cl
        mov si, offset dec_number
        add si, 2
        call BYTE_TO_DEC
        call offset_dec
        mov dx, si
        call print_string
        mov dl, ':'
        mov ah, 02h
        int 21h
        mov dl, ' '
        mov ah, 02h
        int 21h
        call print_mcb 
        call print_n
        mov al, es:[0]
        cmp al, 5ah
     je end_mcb_list

        mov bx, es:[3]
        mov ax, es
        add ax, bx
        inc ax
        mov es, ax
        inc cl
        jmp print_list

end_mcb_list:
    pop dx
    pop es
    pop bx
    pop ax
ret
print_mcb_list endp

delete_free_memory proc near
    push ax
    push bx
    push cx
    push dx
    
    lea ax, final_end
    mov bx,10h
    sub dx,dx
    div bx
    inc ax
    mov bx,ax
    mov al,0
    mov ah,4Ah
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
ret
delete_free_memory endp

BEGIN:
   
    call print_available_mem_size
    call print_extended_mem_size

    call delete_free_memory
    call print_mcb_list

; Выход в DOS
 xor AL,AL
 mov AH,4Ch
 int 21H
 final_end:
TESTPC ENDS
 END START ;конец модуля, START - точка входа