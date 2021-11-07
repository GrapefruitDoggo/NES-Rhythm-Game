.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

.segment "VARS"
    level: .res $100

.segment "IMG"
.incbin "../assets/tiles/game_tiles.chr"

.include "./define/header.asm"
.include "./lib/utils.asm"
.include "./lib/gamepad.asm"
.include "./lib/ppu.asm"
.include "./define/palette.asm"
.include "./define/level.asm"
.include "./define/sprites.asm"

.include "./interrupt/irq.asm"              ; not currently using irq code, but it must be defined
.include "./interrupt/reset.asm"            ; code and macros related to pressing the reset button
.include "./interrupt/nmi.asm"

;#$120

gen_screen:
    lda #$c0
    sta scroll_x

    jsr draw_background
    jsr draw_attribute
    jsr load_sprites

    lda $0200
    sta player_y
    lda $0203
    sta player_x

game_loop:
    lda nmi_ready
    bne game_loop

    jsr set_gamepad

    set nmi_ready, #$01

    ;jsr move_player

    jmp game_loop
