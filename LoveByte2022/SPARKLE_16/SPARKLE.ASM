; Sierpiński Sparkle 16
;   by P_Malin / Bitshifters
;     A 16b (well, 15b) MSDos Effect
;
; Released at Lovebyte  2022

lds di,[bx] ; DosBox

;push 0xa000 ; FreeDOS says hi
;pop ds

mov al,0x13
int 0x10

L:

mov bx,ax
and bh,bl
inc byte [bx]
inc ax
jmp short L
