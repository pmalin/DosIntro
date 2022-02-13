; ============================================================================
;
; Stellar 64
;
; by P_Malin / Bitshifters
;
; A 64b MSDos Intro
; 
; Released at Lovebyte 2022
; 
; ============================================================================


org 100h

  ; set mode 0x13
  mov  al,0x13
  int  0x10

  ; set safer ds placement for star buffer
  ;    ah whatever, comment it out and just trash 0->0xff
  ;add  dh,al         ; ds = cs + 0x1300
  ;mov  ds,dx

  ; MIDI - set UART mode
  mov dx,0x331
  mov al,0x3f
  out dx,al

  dec dx ; dx = 0x330
  push cx ; we want 255 in dx later so we push it here

  rep outsb ; write 255 bytes (program) as midi data (most sections do nothing)

  push 0xa002 ; screen start + horizontal offset
              ; 0xa000[screen start] + ((320[screen width] - 256[effect width]) / 2) / 16[segment size]

  ; start of midi data
  db 0xc0 ; set channel 0 instrument...
  db 54 ; ... to "voice oohs"
  db 0x90 ; play channel 0 note...
  db 28 ; low note
  db 127  ; volume
  ; end of midi data
  ; but the next two instructions are also a low note
  ; ... 

  pop es ; get screen write address
  pop dx ; reset dh to 0 (or any constant value) and 255 in dl for first pass velocity AND mask
  
L:
  ;xor dh,dh - dh is now cleared in end of loop mov dx,15
  xor di,di ; reset screen position
  ;xor bh,bh ; already zero on init and kept at zero
  mov cl,200 ; scanline count
Y:
  mov si,cx ; get star buffer index from scanline index
  add dh,cl ; add curr index to get random star col / vel
  
  mov al,dh ; get in al and mask to get reduced range
  and al,dl ; dh = random (vel / col)

  mov bl,[ds:si] ; read star curr x
  mov [es:di+bx],bh ; clear prev pixel
  add bl,al ; add velocity
  mov [ds:si],bl ; store star new x

  add al,16 ; get grey portion of default palette
  mov [es:di+bx],al ; write curr pixel

  add di,320 ; next scanline
  loop Y  

  mov dx,15 ; reset dh to 0 (or any constant value) set dl to 15 for subsequent frame velocity AND mask
  hlt ; cheap vsync
  jmp L

