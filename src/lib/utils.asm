.segment "CODE"

; this is like a x = y call where x is set to the value of y
.macro set set_var, from
    lda from
    sta set_var
.endmacro

; this procedure will loop until the next vblank
.proc wait_for_vblank
  	bit PPU_STATUS      ; $2002
        vblank_wait:
    		bit PPU_STATUS  ; $2002
    		bpl vblank_wait

        rts
.endproc

; clear out all the ram on the reset press
.macro clear_ram
  	lda #0
  	ldx #0
  	clear_ram_loop:
    		sta $0000, X
    		sta $0100, X
    		sta $0200, X
    		sta $0300, X
    		sta $0400, X
    		sta $0500, X
    		sta $0600, X
    		sta $0700, X
    		inx
    		bne clear_ram_loop
.endmacro

; this code will be called from the nmi
.macro draw_tile_nmi ID, HI, LO

    lda PPU_STATUS        ; PPU_STATUS = $2002

    lda HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda LO
    sta PPU_ADDR

    lda ID
    sta PPU_DATA
.endmacro

.proc draw_background
    jsr wait_for_vblank

    ldy #$20
    ldx #$00

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    render_loop_1:
        lda minesweeper, x
        sta PPU_DATA

        inx
        bne render_loop_1

    jsr wait_for_vblank

    ldy #$21

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    render_loop_2:
        lda minesweeper+$0100, x
        sta PPU_DATA

        inx
        bne render_loop_2

    jsr wait_for_vblank

    ldy #$22

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    render_loop_3:
        lda minesweeper+$0200, x
        sta PPU_DATA

        inx
        bne render_loop_3

    jsr wait_for_vblank

    ldy #$23

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    render_loop_4:
        lda minesweeper+$0300, x
        sta PPU_DATA

        inx
        cpx #$bf
        bne render_loop_4
.endproc

.proc draw_attribute
    jsr wait_for_vblank

    lda PPU_STATUS        ; PPU_STATUS = $2002

    lda #$23
    sta PPU_ADDR          ; High byte
    lda #$c0
    sta PPU_ADDR          ; Low byte

    ldx #$00

    attribute_loop_1:
        lda attribute, x
        sta PPU_DATA

        inx
        cpx #$40
        bne attribute_loop_1
.endproc


.proc load_sprites
loadsprites:
    lda sprites, x      ; accesses each sprite in sprites (defined in sprites.asm) starting at index 0
    sta $0200, x        ; store in sprite memory location
    inx
    cpx #$A4            ; each sprite holds 4 bytes of data - Ycoord, tile, attributes and Xcoord - and there are 41 sprites, so 4*41 = 164, or $A4
    bne loadsprites
.endproc

/*
; not enough space in prg for these, will need to make space elsewhere
; (actually nvm, there *is* enough space, but the game mysteriously won't work when i uncomment this stuff still even though it's not being called anywhere i think :T)
.proc move_player
    lda gamepad_new_press
    and #%01000000
    bne left_press

    lda gamepad_new_press
    and #%10000000
    bne right_press

    lda gamepad_new_press
    and #%00010000
    bne up_press

    lda gamepad_new_press
    and #%00100000
    bne down_press

left_press:
    lda player_x
    sbc #$08
    sta player_x
    rti

right_press:
    lda player_x
    adc #$08
    sta player_x
    rti

up_press:
    lda player_y
    sbc #$08
    sta player_y
    rti

down_press:
    lda player_y
    sbc #$08
    sta player_y
    rti
.endproc

.proc update_player_sprite
    lda player_y
    sta $0200

    lda player_x
    sta $0203
.endproc
*/
