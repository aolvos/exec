;exec by SATAGAX, 2021
;code: aolvos

;haven't coded 4 MSDOS for a long time ...
;02/21/2021, 12:00 AM: feelin' lazy :)
;greetz fly to all sizecoders!

bits 16
org 0x100

;setting videomode
mov ah,00h
mov ax,13h
int 10h

;main loop
reset:
xor dx,dx ;counter

main:
push dx

;-=[start of drawing]=-

;drawing.. some hell >:)

draw:
push 0a000h ;vga adress
pop es
push 09000h ;screen buffer adress
pop fs
push 0ffa6h ;ROM 8x8 font adress
pop gs

;draw background

xor di,di
mov cx,320 * 200
fill:
push dx
push cx
shr dx,3 ;slow it down!
add dx,cx
mov al,56

shr cl,1
test cl,6
jz putpixel

test ch,6
jnz putpixel

test dl,8
jz putpixel

inc al
putpixel:
mov [fs:di],al
inc di
pop cx
pop dx
loop fill

;next step is to get BIOS font data. it's located at FFA6:000E
;font is stored as an 8x8 array of bits. let's do it!

push dx
mov si,string
mov di,320 * 84 + 17 ;shadow position on screen
mov bl,20
call print

pop dx
mov si,string
;xor di,di
mov di,320 * 82 + 11 ;text position on screen
mov bl,34
call print

;now it's time to copy everything drawn in buffer to screen

mov cx,64000
xor di,di

to_screen:
mov ax,[fs:di]
stosb
loop to_screen

;-=[end of drawing]=-

pop dx
inc dx

mov ah,01h ;check if key was pressed..
int 16h
jz main

;goodbye, galaxy!
go_away:
mov ah,0x4c
int 21h

print:
mov cx,8

lodsb
test al,al
jz stop_it
mul cl
xchg bx,ax ;bx: glyph position in memory, ax: color

mov cl,8 * 4

draw_letter:
push ax
push cx
mov cl,8
mov ah,[gs:0x000e + bx] ;get row

add di,8 * 4 ;sadly, i have to flip letterz

draw_row:

test ah,1
jz skip

;if bit is set then draw + scale
push bx
xor bx,bx
scale_row:
;make it wavy!
push di
push ax
push dx
;scale a little bit
mov ax,4
mul cl
add dx,ax
add dx,bx

;sine sine sine sine
;get sine value from degrees using FPU

push dx
mov bp,sp
fild word[bp] ;ST(0): dx
fldpi ;ST(0): pi, ST(1): dx

;converting degrees to radians...
fmulp ;ST(0): pi*dx
mov word[bp],180
fidiv word [bp] ;store radians

;calculate sine!
fsin ;ST(0): sine

;scale it!
mov word[bp],24
fimul word[bp]

;store rounded result
fistp word[bp]

pop dx

;add it to di
mov ax,320
mul dx
add di,ax

pop dx
pop ax
;now di is beautiful

mov [fs:di + bx],al

;restore di
pop di
inc bl
cmp bl,4
jb scale_row
pop bx

skip:
shr ah,1 ;next bit
;dec di
sub di,4
loop draw_row

add di,320
pop cx

dec cl

;check if number is divisible by 8
test cl,3
jnz skip_inc

inc bx ;ask for next row
skip_inc:
inc cl
pop ax
loop draw_letter
mov bl,al
sub di,320 * 8 * 4 - 8 * 4
add dx,32
jmp print

stop_it:
ret

string db 3,'SATAGAX',3,0