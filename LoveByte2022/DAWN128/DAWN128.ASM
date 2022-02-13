; ============================================================================
; Dawn128
;
;	by P_Malin / Bitshifters
;
; A 128b MSDos Intro
; 
; Released at Lovebyte 2022
; 
; ============================================================================

; horrible audio
;%define AUDIO_A

; also horrible
;%define AUDIO_B

org 100h

	; ===================
	;  Set Graphics Mode
	; ===================

	; call int 0x10
	; AH = 0 set video mode
	;  set mode to AL = 0x13 (320 x 200 pixels in 256 colors)
	mov al,0x13 

%ifdef AUDIO_A	
	out 61h,al		; connect timer to speaker
%endif	

	int 0x10

	; set es to video memory and also encode the screen X offset (-160 / 16)
	push 	0x0a000 - 10	
	pop es

	; =============
	;  Set Palette
	; =============

palloop:
	mov dx,0x3c8
	mov al,bh
	out dx,al  
	inc dx

	mov al,63
	mov cl,4
palchannelloop:
    sub al,bh
    jnc noclip
    xor al,al
noclip:
cmp cl,2
jz skip
	out dx,al    ; write value (0..63)
skip:
	loop palchannelloop

	inc bx
	jnz palloop

	; ===========
	;  Main Loop
	; ===========

XO equ 9
YO equ 8
OUTO equ 8

	fninit 			; init fpu

L:
	mov ax,0xcccd   ; Rrrola trick
	mul di 			; Rrrola trick dh,dl are now screen coords Y,X

	sub dh,90 		; offset screen Y

	pusha

%ifdef AUDIO_A
	and al,0x1f
	out 42h,al
%endif	

scale_const:
	; load y from CPU stack
	fild word [bx-YO] ; y             LOAD Y 				

	; load x from CPU stack
	fild word [bx-XO] ; x             LOAD X  				


	; test if bottom half of screen / also skip 0 length case
	dec dh
	js nowater

%ifdef AUDIO_B	
	out 0x61,al
%endif	

	; apply sea effect

	; get Z  =  (PI/y)
	fldpi
	fdiv st2 ; st2 is current y on floating point stack

	fld st0 ; dup 1/y
	fild word [byte si+scale_const-100h] ; random constant to scale wave size

	call mulp_add_time_and_do_sin  ; get wibble based on Z

	fadd st2 ; add wavy offset to x

	call mulp_add_time_and_do_sin ; get wibble based on X (scaled by Z)
	
	faddp	; add wibble to original x

	fxch ; swap x<->y; get y to top of stack

	; stretch Y a bit in the reflection
	fldpi
	fdivp

nowater:

	; square x
	fmul st0
	fxch ; swap x<->y; get x to top of stack
	; square y
	fmul st0

	; d = sqrt(x^2 + y^2)
	faddp
	fsqrt

	fistp word [bx-OUTO] ; store result in dx
	popa	

	; add dither
	; ah is random junk from Rrrola trick, 
	; setting ah from flags we can get a bit into the carry flag 
	; and add that to the result by using adc below for a cheap dither
	sahf ; 1b

	; expand by sun radius	
	adc dh, 256-10 ; 3b - sun radius
	salc 	; 1b - get carry flag as 0x00 or 0xff in al and use this to set colour to 0 if carry 
			; (sub changed to add to get carry we want)
	and al,dh ; 2b

	shr al,1 ; get colour in correct range

	stosb

	; make horrible sounds

	loop L

	; "vsync"
%ifndef AUDIO_A	
%ifndef AUDIO_B
	HLT
	HLT
%endif
%endif

	inc word[si]

	in al,0x60 ; keyboard port
	das ; no need to clear ah if we use this but will exit on any keypress
	jp L

	ret ; could fallthrough into subroutine below which also does a ret but we have a byte spare

mulp_add_time_and_do_sin:
	fmulp		
scale_const2:	
	fiadd word [si] ; add time
	fsin
	fimul word [byte si+scale_const2-100h] ; scale up by random constant
	ret
