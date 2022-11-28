; lots of this code (and some of the comments) isn't mine, mostly because i didn't want to spend half a year learning the 6502 architecture and nes mapping before i could even
; start writing a game - i learn better by actually trying to code something :3
; The base 'engine' code comes from: https://github.com/battlelinegames/nes-starter-kit

.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

; after we load the sprites, we know that this one should always point to the player's y and x position respectively, unless something has gone horribly wrong
.define PlayerY $0200
.define PlayerX $0203

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
    lda #$c0
    sta scroll_x

    jsr draw_background
    jsr draw_attribute  ; the attribute table is basically where all the colour palettes get assigned to regions on the screen
    jsr load_sprites

game_loop:
    lda nmi_ready
    bne game_loop ; if nmi_ready equals anything but 0, this will send us back up to line 37 - nmi_ready will be set to 0 when an NMI has occurred
                  ; when we're not waiting for a non-maskable interrupt (NMI), we can proceed, to give us the most program time possible before the next one

    jsr check_gamepad ; this basically reads the gamepad inputs and sets a bunch of things - more info in gamepad.asm

    set nmi_ready, #$01 ; this is a macro! they're a fun thing that ca65 has where it'll replace this with some predefined code - this one, set, is in utils.asm

    ; here is where we'd run our game logic. for now, that's just moving the player cursor diagonally down and right, because... well why not really :3

    jsr button_logic

    jmp game_loop
