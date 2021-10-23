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
.macro draw_tile_nmi ID, COL, ROW ; 16, 4
    .local BYTE_OFFSET_HI
    .local BYTE_OFFSET_LO

    BYTE_OFFSET_HI = ((ROW) * 32 + COL) / 256 + 32 ; (16 * 32 + 4) / 256 + 32
    BYTE_OFFSET_LO = ((ROW) * 32 + COL) .mod 256

    lda PPU_STATUS        ; PPU_STATUS = $2002

    lda #BYTE_OFFSET_HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda #BYTE_OFFSET_LO
    sta PPU_ADDR

    lda ID
    sta PPU_DATA
.endmacro

; 2nd digit must always be even, when getting to x = #$ff, iny
.proc draw_board
    ldy #$20
    ldx #$00
    stx board_pointer         ; board_pointer will be used to cycle through the board, telling us which sprites to render

    render_loop:
        lda PPU_STATUS        ; PPU_STATUS = $2002

        sty PPU_ADDR          ; High byte
        stx PPU_ADDR          ; Low byte

        ; here we're checking if the 2nd digit of x is about to be odd - if it is, we advance until it becomes even again
        txa
        and #%00011111
        cmp #%00001111
        bne continue_loop                  ; if the and op gave us #%00001111 (i.e. if whem we inx, x's 2nd digit will be odd), we run the code below
            txa
            adc #$0f
            tax

    continue_loop:
        txs                   ; shove x into the stack so we can use board_pointer
        ldx board_pointer
        lda board, x
        sta PPU_DATA
        tsx

        inc board_pointer     ; if board_pointer is 0, we should eject ourselves out of the loop
        beq board_end

        inx
        bne render_loop

        iny
        cmp #$24
        bne render_loop
    board_end:
.endproc
