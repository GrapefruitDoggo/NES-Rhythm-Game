.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

.segment "VARS"
    level: .res $3C0

.segment "IMG"
.incbin "../assets/tiles/game_tiles.chr"

.include "./define/header.asm"
.include "./lib/utils.asm"
.include "./lib/gamepad.asm"
.include "./lib/ppu.asm"
.include "./define/palette.asm"
.include "./define/level.asm"

.include "./interrupt/irq.asm"              ; not currently using irq code, but it must be defined
.include "./interrupt/reset.asm"            ; code and macros related to pressing the reset button
.include "./interrupt/nmi.asm"

gen_screen:
    lda #$c0
    sta scroll_x

    ldx #$00
    gen_screen_loop:
        lda minesweeper, x
        sta $0300, x
        lda minesweeper+$0100, x
        sta $0400, x
        lda minesweeper+$0200, x
        sta $0500, x
        lda minesweeper+$0300, x
        sta $0600, x
        inx
        bne gen_screen_loop

        jsr draw_screen

game_loop:
    lda nmi_ready
    bne game_loop

    jsr set_gamepad

    set nmi_ready, #$01

    jmp game_loop
