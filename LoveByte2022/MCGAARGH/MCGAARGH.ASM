; MCGAargh
;   by P_Malin / Bitshifters
;     A 32b MSDos Effect
;
; Released at Lovebyte  2022
mov al,0x13
int 0x10

les di,[bx]

pop ds

F:
mov bl,[0x046c]
mov ax,di
shl ax,2

xor al,bl

imul ah

mov al,ah
add al,bl

and al,15
add al,32

stosb

jmp  F
