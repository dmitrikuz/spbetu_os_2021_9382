stacks segment stack
	dw 128 dup(?)
stacks ends

data segment
	parameters 		dw 0
			   		dd 0
			   		dd 0
			   		dd 0

	program 		db 'l2.com', 0
	flag 			db 0
	cmd 			db 1h, 0dh
	pos 			db 128 dup(0)

	keep_ss 		dw 0
	keep_sp 		dw 0
	keep_psp 		dw 0

	mcb_err 		db 'Error: MCB crashed!', 0dh, 0ah, '$'
	no_memory_err 	db 'Error: Not enough memory!', 0dh, 0ah, '$'
	address_err 	db 'Error: Invalid memory address!', 0dh, 0ah, '$'
	function_err 	db 'Error: Invalid function number', 0dh, 0ah, '$'
	file_err		db 'Error: File not found!', 0dh, 0ah, '$'
	disk_err 		db 'Error: Disk error!', 0dh, 0ah, '$'
	memory_err 		db 'Error: Insufficient memory!', 0dh, 0ah, '$'
	environment_err db 'Error: Wrong string of environment! ', 0dh, 0ah, '$'
	format_err 		db 'Error: Wrong format!', 0dh, 0ah, '$'
	free_mem 		db 'Memory has been freed!' , 0dh, 0ah, '$'
	successful_end 	db 0dh, 0ah, 'Program ended with code:    ' , 0dh, 0ah, '$'
	interrupt_end 	db 0dh, 0ah, 'Program ended by ctrl-break' , 0dh, 0ah, '$'
	device_err 		db 0dh, 0ah, 'Program ended by device_end error' , 0dh, 0ah, '$'
	int_end 		db 0dh, 0ah, 'Program ended by int 31h' , 0dh, 0ah, '$'

	end_data 		db 0
data ends

code segment

assume cs:code, ds:data, ss:stacks

myprint proc
 	push ax
 	mov ah, 09h
 	int 21h
 	pop ax
 	ret
myprint endp

mem_free proc
	push ax
	push bx
	push cx
	push dx

	mov ax, offset end_data
	mov bx, offset lastt
	add bx, ax

	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h

	jnc leaveef
	mov flag, 1

mcb_crash:
	cmp ax, 7
	jne not_enougth_mem
	mov dx, offset mcb_err
	call myprint
	jmp enddd

not_enougth_mem:
	cmp ax, 8
	jne address
	mov dx, offset no_memory_err
	call myprint
	jmp enddd

address:
	cmp ax, 9
	mov dx, offset address_err
	call myprint
	jmp enddd

leaveef:
	mov flag, 1
	mov dx, offset free_mem
	call myprint

enddd:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
mem_free endp

load proc
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	mov keep_sp, sp
	mov keep_ss, ss

	mov ax, data
	mov es, ax
	mov bx, offset parameters
	mov dx, offset cmd
	mov [bx+2], dx
	mov [bx+4], ds
	mov dx, offset pos

	mov ax, 4b00h
	int 21h

	mov ss, keep_ss
	mov sp, keep_sp
	pop es
	pop ds

	jnc loads

functio_error:
	cmp ax, 1
	jne file_error
	mov dx, offset function_err
	call myprint
	jmp load_end
file_error:
	cmp ax, 2
	jne disk_error
	mov dx, offset file_err
	call myprint
	jmp load_end
disk_error:
	cmp ax, 5
	jne memory_error
	mov dx, offset disk_err
	call myprint
	jmp load_end
memory_error:
	cmp ax, 8
	jne environment_error
	mov dx, offset memory_err
	call myprint
	jmp load_end
environment_error:
	cmp ax, 10
	jne format_error
	mov dx, offset environment_err
	call myprint
	jmp load_end
format_error:
	cmp ax, 11
	mov dx, offset format_err
	call myprint
	jmp load_end

loads:
	mov ah, 4dh
	mov al, 00h
	int 21h
	cmp ah, 0
	jne ctrlc_end
	push di
	mov di, offset successful_end
	mov [di+26], al
	pop si
	mov dx, offset successful_end
	call myprint
	jmp load_end

ctrlc_end:
	cmp ah, 1
	jne device_end
	mov dx, offset interrupt_end
	call myprint
	jmp load_end
device_end:
	cmp ah, 2
	jne int_31h_end
	mov dx, offset device_err
	call myprint
	jmp load_end
int_31h_end:
	cmp ah, 3
	mov dx, offset int_end
	call myprint

load_end:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
load endp

find_path proc
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	push es

	mov ax, keep_psp
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0

look_for_p:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne look_for_p

	cmp byte ptr es:[bx+1], 0
	jne look_for_p

	add bx, 2
	mov di, 0

work_work:
	mov dl, es:[bx]
	mov byte ptr [pos+di], dl
	inc di
	inc bx
	cmp dl, 0
	je work_end
	cmp dl, '\'
	jne work_work
	mov cx, di
	jmp work_work

work_end:
	mov di, cx
	mov si, 0

_fn:
	mov dl, byte ptr [program+si]
	mov byte ptr [pos+di], dl
	inc di
	inc si
	cmp dl, 0
	jne _fn


	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
find_path endp

main proc far
	push ds
	xor ax, ax
	push ax
	mov ax, data
	mov ds, ax
	mov keep_psp, es
	call mem_free
	cmp flag, 0
	je leavee
	call find_path
	call load
leavee:
	xor al, al
	mov ah, 4ch
	int 21h

main      endp

lastt:
code ends
end main
