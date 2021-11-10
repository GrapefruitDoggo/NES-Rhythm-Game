.segment "CODE"

; this is basically an x = y, or in this case target = source
.macro set target, source
    lda source
    sta target
.endmacro

; this procedure will loop until the next vblank - something i have yet to look up, really... maybe this is why i'm having problems? ^-^'
.proc wait_for_vblank
  	bit PPU_STATUS      ; $2002
        vblank_wait:
    		bit PPU_STATUS  ; $2002
    		bpl vblank_wait

        rts
.endproc

; clear out all the ram - used in reset.asm
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

; this code draws a single background tile to the screen! currently unused, but will be used when you can actually like select tiles and other gameplay things
.macro draw_tile ID, HI, LO

    lda PPU_STATUS        ; PPU_STATUS = $2002

    ; here we're telling the ppu where on the screen to put the tile we're about to give it - first the hi bit (say $20), then the lo bit (say, idk, $21)
    ; which forms the two-bit address $2021 :3
    lda HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda LO
    sta PPU_ADDR

    lda ID  ; the id of the tile we want to draw - each 8x8 pixel square on a tilesheet counts as one 'id' in this system
    sta PPU_DATA
.endmacro

; this code runs at the start of the game and basically copies everything from level.asm to ppu memory - initialising the gameboard essentially
; it's basically just draw_tile a bunch, but split into 4 seperate loops because there isn't enough time per frame to do all of this.
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

; like draw_background, but for the attribute table - much shorter, cos there's a lot less data to transfer
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

; this loads all the sprites in sprites.asm. this is to save having to spawn in (and keep track of) new ones later, which would take up already sparse resources
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
; actually nvm, there *is* enough space, but the game mysteriously won't work when i uncomment this stuff still even though it's not being called anywhere? :T
; need to do more research on why adding stuff to the prg rom might cause the program to spontaneously combust 
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
