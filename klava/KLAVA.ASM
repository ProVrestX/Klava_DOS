.model tiny
.code
org 100h
.186

VIDEOSEG equ 0b800h

.data
FrameWall db '+-+| |+-+'
TextStr db 'AX: BX: CX: DX: '
RegsStr db 16 dup(0)

.code
Start:
		xor ax, ax
		mov es, ax
		mov bx, 09h * 4
		
		mov ax, es:[bx]
		mov Old09Ofs, ax
		mov ax, es:[bx+2]
		mov Old09Seg, ax
		
		cli
		mov es:[bx], offset New09
		push cs
		pop ax
		mov es:[bx+2], ax
		sti

		mov bx, 08h * 4
		mov ax, es:[bx]
		mov Old08Ofs, ax
		mov ax, es:[bx+2]
		mov Old08Seg, ax

		cli
		mov es:[bx], offset NewTim
		push cs
		pop ax
		mov es:[bx+2], ax
		sti
		
		mov ax, 3100h
		mov dx, offset EOP
		shr dx, 4
		inc dx
		int 21h

;------------------------------------------------
New09		proc
		push ax bx es

		push VIDEOSEG	
		pop es
		mov ah, 4eh
		mov bx, 1*80*2 + 40*2
		
		in al, 60h
		mov es:[bx], ax
		
		in al, 61h
		mov ah, al
		or al, 80h
		out 61h, al
		mov al, ah
		out 61h, al
		
		mov al, 20h
		out 20h, al
		
		call FillFrameWall
		call FillTextStr
		call DrawFrame
		call DrawText

		pop es bx ax
		db 0eah
Old09Ofs	dw 0
Old09Seg	dw 0

		iret
		endp
;------------------------------------------------

;------------------------------------------------
NewTim		proc
		push ax bx cx dx si di es
		
		mov di, offset RegsStr

		call WordToHex

		mov ax, bx
		call WordToHex

		mov ax, cx
		call WordToHex

		mov ax, dx
		call WordToHex

		call DrawRegs
		
		pop es di si dx cx bx ax
		db 0eah
Old08Ofs	dw 0
Old08Seg	dw 0

		iret
		endp
;------------------------------------------------

;------------------------------------------------
FillFrameWall proc
		mov di, offset FrameWall ;'+-+| |+-+'

		mov word ptr [di], '-+'
		mov word ptr [di+2], '|+'
		mov word ptr [di+4], '| '
		mov word ptr [di+6], '-+'
		mov byte ptr [di+8], '+'

		ret 
		endp
;------------------------------------------------

;------------------------------------------------
FillTextStr proc
		mov di, offset TextStr ;'AX: BX: CX: DX: '

		mov word ptr [di], 'XA'
		mov word ptr [di+2], ' :'
		add di, 4
		mov word ptr [di], 'XB'
		mov word ptr [di+2], ' :'
		add di, 4
		mov word ptr [di], 'XC'
		mov word ptr [di+2], ' :'
		add di, 4
		mov word ptr [di], 'XD'
		mov word ptr [di+2], ' :'

		ret 
		endp
;------------------------------------------------

;------------------------------------------------
WordToHex proc
		push ax bx cx

		mov cx, 4
		mov bx, ax

ConvertLoop:
		rol bx, 4       
		mov al, bl
		and al, 0Fh
		add al, '0'
		cmp al, '9'
		jle NumIsDec
		add al, 'A' - '9' - 1

NumIsDec:
		stosb
		loop ConvertLoop

		pop cx bx ax

		ret
		endp
;------------------------------------------------

;------------------------------------------------
; Draw a frame
;------------------------------------------------
DrawFrame	proc

		push VIDEOSEG	
		pop es
		mov di, 0
		mov ah, 05ah
		
		mov si, offset FrameWall
		mov cx, 12
		call DrawLine
		
		mov cx, 6
		mov di, 160

DrawFrameLoop:	
		push cx

		mov si, offset FrameWall
		add si, 3
		mov cx, 12
		call DrawLine
		
		pop cx
		mov dx, 1 + 6 + 1
		sub dx, cx
		imul dx, 160
		mov di, dx
		loop DrawFrameLoop	

		mov si, offset FrameWall
		add si, 6
		mov cx, 12
		call DrawLine
		
		ret
		endp
;------------------------------------------------

;------------------------------------------------
; Draw a line
; Entry: SI - 3-Bit string for line 
;	 CX - width line
;	 ES:DI - addr video mem
;	 AH - color attr
;------------------------------------------------
DrawLine	proc
		
		cld

		lodsb
		stosw
		
		lodsb
		sub cx, 2
		rep stosw
		
		lodsb
		stosw

		ret
		endp
;------------------------------------------------

;------------------------------------------------
; Draw text to frame
;------------------------------------------------
DrawText	proc

		push VIDEOSEG	
		pop es
		mov di, 0
		mov ah, 05ah

		mov cx, 4	
		mov si, offset TextStr

LoopText: 
		mov dx, cx
		imul dx, 160
		mov di, 160*6 + 2*2
		sub di, dx
		push cx
		mov cx, 4
		call InsText 

		pop cx
		loop LoopText


		ret
		endp
;------------------------------------------------

;------------------------------------------------
; Draw regs to frame
;------------------------------------------------
DrawRegs	proc

		push VIDEOSEG	
		pop es
		mov di, 0
		mov ah, 05ah

		mov cx, 4	
		mov si, offset RegsStr

LoopRegs: 
		mov dx, cx
		imul dx, 160
		mov di, 160*6 + 6*2
		sub di, dx
		push cx
		mov cx, 4
		call InsText 

		pop cx
		loop LoopRegs


		ret
		endp
;------------------------------------------------

;------------------------------------------------
; Draw text to frame
; Entry: CX - length str
;	 SI - addr str
;	 ES:DI - addr video mem
;	 AH - color attr
;------------------------------------------------
InsText	proc

LoopInsText:
		lodsb
		stosw

		loop LoopInsText

		ret
		endp
;------------------------------------------------



EOP:
end		Start