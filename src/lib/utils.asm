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
.macro draw_tile_nmi ID, HI, LO ; 16, 4

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
