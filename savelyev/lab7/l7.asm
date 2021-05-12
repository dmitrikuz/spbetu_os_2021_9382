stacks segment stack
	dw 128 dup(?)
stacks ends

data segment
	o1 db "o1.ovl", 0
	o2 db "o2.ovl", 0

	program dw 0
	data_memory db 43 dup(0)
	flag db 0
	pos db 128 dup(0)
	ovls_addr dd 0
	keep_psp dw 0

	eof                      db 0dh, 0ah, '$'
    mcb_err 		         db 'Error: MCB crashed!', 0dh, 0ah, '$'
    no_memory_err 	         db 'Error: Not enough memory!', 0dh, 0ah, '$'
    address_err 	         db 'Error: Invalid memory address!', 0dh, 0ah, '$'
    free_mem 		         db 'Memory has been freed!' , 0dh, 0ah, '$'
    file_err		         db 'Error: File not found!(load)', 0dh, 0ah, '$'
	function_err             db 'Error: function doesnt exist!', 0dh, 0ah, '$'
	path_err                 db 'Error: path not found!', 0dh, 0ah, '$'
	files_err                db 'Error: you opened too many files!', 0dh, 0ah, '$'
	access_err               db 'Error: no access!', 0dh, 0ah, '$'
	memory_err               db 'Error: insufficient memory!', 0dh, 0ah, '$'
	environment_err          db 'Error: wrong string of environment!', 0dh, 0ah, '$'
	successful_end           db 'Load was successful!', 0dh, 0ah, '$'
	no_err                   db 'Memory allocated successfully!', 0dh, 0ah, '$'
	file_not_err             db 'Error: file not found!(allocation memory)' , 0dh, 0ah, '$'
	route_err                db 'Error: route not found!' , 0dh, 0ah, '$'
	end_data                 db 0

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

	mov ax, data
	mov es, ax
	mov bx, offset ovls_addr
	mov dx, offset pos
	mov ax, 4b03h
	int 21h

	jnc loads

functio_error:
	cmp ax, 1
	jne file_error
	mov dx, offset eof
	call myprint
	mov dx, offset function_err
	call myprint
	jmp load_end
file_error:
	cmp ax, 2
	jne path_error
	mov dx, offset file_err
	call myprint
	jmp load_end
path_error:
	cmp ax, 3
	jne files_error
	mov dx, offset eof
	call myprint
	mov dx, offset path_err
	call myprint
	jmp load_end
files_error:
	cmp ax, 4
	jne access_error
	mov dx, offset files_err
	call myprint
	jmp load_end
access_error:
	cmp ax, 5
	jne memory_error
	mov dx, offset access_err
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
	mov dx, offset environment_err
	call myprint
	jmp load_end

loads:
	mov dx, offset successful_end
	call myprint

	mov ax, word ptr ovls_addr
	mov es, ax
	mov word ptr ovls_addr, 0
	mov word ptr ovls_addr+2, ax

	call ovls_addr
	mov es, ax
	mov ah, 49h
	int 21h

load_end:
	pop es
	pop ds
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

	mov program, dx

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
	mov si, program

fn:
	mov dl, byte ptr [si]
	mov byte ptr [pos+di], dl
	inc di
	inc si
	cmp dl, 0
	jne fn


	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	ret
find_path endp

allocation_mem proc
	push ax
	push bx
	push cx
	push dx

	push dx
	mov dx, offset data_memory
	mov ah, 1ah
	int 21h
	pop dx
	mov cx, 0
	mov ah, 4eh
	int 21h

	jnc no_error

file_not_error:
	cmp ax, 2
	je no_path_error
	mov dx, offset file_not_err
	call myprint
	jmp leaveeee
no_path_error:
	cmp ax, 3
	mov dx, offset route_err
	call myprint
	jmp leaveeee

no_error:
	push di
	mov di, offset data_memory
	mov bx, [di+1ah]
	mov ax, [di+1ch]
	pop di
	push cx
	mov cl, 4
	shr bx, cl
	mov cl, 12
	shl ax, cl
	pop cx
	add bx, ax
	add bx, 1
	mov ah, 48h
	int 21h
	mov word ptr ovls_addr, ax
	mov dx, offset no_err
	call myprint

leaveeee:
	pop dx
	pop cx
	pop bx
	pop ax
	ret
allocation_mem endp

start proc
	push dx
	call find_path
	mov dx, offset pos
	call allocation_mem
	call load
	pop dx
	ret
start endp

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

	mov dx, offset o1
	call start
	mov dx, offset eof
	call myprint
	mov dx, offset o2
	call start

leavee:
	xor al, al
	mov ah, 4ch
	int 21h
main endp
lastt:
code ends
end main
