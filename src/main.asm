; lots of this code (and some of the comments) isn't mine, mostly because i didn't want to spend half a year learning the 6502 architecture and nes mapping before i could even
; start writing a game - i learn better by actually trying to code something :3
; The base 'engine' code comes from: https://github.com/battlelinegames/nes-starter-kit

.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

; after we load the sprites, we know that this one should always point to the player cursor's y and x position respectively, unless something has gone horribly wrong
.define CursorY $0200
.define CursorX $0203

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
.include "./define/title.asm"
.include "./define/sprites.asm"

.include "./interrupt/irq.asm"              ; not currently using irq code, but it must be defined
.include "./interrupt/reset.asm"            ; code and macros related to pressing the reset button
.include "./interrupt/nmi.asm"

.segment "CODE"
; i put this right at the start of the program mostly as a hackey way to get around the fact that it takes more than one frame to draw all of this stuff
; and i don't know enough about the NES or 6502 to really mitigate that, it should work fine though i hope :3
gen_screen:
    jsr wait_for_vblank
    jsr disable_rendering

    lda #$c0
    sta scroll_x

    jsr draw_background
    jsr draw_attribute  ; the attribute table is basically where all the colour palettes get assigned to regions on the screen
    jsr load_sprites

    jsr enable_rendering

game_loop:
    lda nmi_ready
    bne game_loop ; if nmi_ready equals anything but 0, this will send us back up to game_loop - nmi_ready will be set to 0 when an NMI has occurred
                  ; when we're not waiting for a non-maskable interrupt (NMI), we can proceed, to give us the most program time possible before the next one

    set nmi_ready, #$01 ; this is a macro! they're a fun thing that ca65 has where it'll replace this with some predefined code - this one, set, is in utils.asm

    ; GAME LOGIC START

    jsr check_gamepad ; this basically reads the gamepad inputs and sets a bunch of things - more info in gamepad.asm

    jsr button_logic

    ; GAME LOGIC END

    jmp game_loop
