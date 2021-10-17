.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

.segment "VARS"
    board: .res 100

.segment "IMG"
.incbin "../assets/tiles/game_tiles.chr"

.include "./define/header.asm"
.include "./lib/utils.asm"
.include "./lib/gamepad.asm"
.include "./lib/ppu.asm"
.include "./define/palette.asm"

.include "./interrupt/irq.asm"              ; not currently using irq code, but it must be defined
.include "./interrupt/reset.asm"            ; code and macros related to pressing the reset button
.include "./interrupt/nmi.asm"


game_loop:
    lda nmi_ready
    bne game_loop

    jsr set_gamepad

    set nmi_ready, #1

    ;inc scroll_y
    lda scroll_y

    cmp #240
    bne not_240
        set scroll_y, #0
    not_240:

    jmp game_loop
