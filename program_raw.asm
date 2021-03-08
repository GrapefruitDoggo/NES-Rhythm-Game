; Compiled with CC65 Compiler

; Rhythm Game

start:
  lda #$01
  sta $4015
  lda #$08
  sta $4002
  lda #$02
  sta $4003
  lda #$bf
  sta $4000
forever:
  jmp forever
