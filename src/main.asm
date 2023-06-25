; TODO: fix screen flicker bug when evaluating/searching tiles
;       impliment in-game timer

; lots of this code (and some of the comments) isn't mine, mostly because i didn't want to spend half a year learning the 6502 architecture and nes mapping before i could even
; start writing a game - i learn better by actually trying to code something :3
; The base 'engine' code comes from: https://github.com/battlelinegames/nes-starter-kit

.linecont       +               ; Allow line continuations
.feature        c_comments      /* allow this style of comment */

; after we load the sprites, we know that this one should always point to the player cursor's y and x position respectively, unless something has gone horribly wrong
.define CursorY $0200
.define CursorX $0203

.segment "VARS"

.segment "IMG"
    .incbin "../assets/tiles/game_tiles.chr"

    .include "./define/header.asm"
    .include "./lib/utils.asm"
    .include "./lib/gamepad.asm"
    .include "./lib/maths.asm"
    .include "./lib/ppu.asm"
    .include "./define/palette.asm"
    .include "./define/level.asm"
    .include "./define/menu.asm"
    .include "./define/sprites.asm"

    .include "./interrupt/irq.asm"              ; not currently using irq code, but it must be defined
    .include "./interrupt/reset.asm"            ; code and macros related to pressing the reset button
    .include "./interrupt/nmi.asm"

.segment "CODE"

load_menu:
    lda #$0 ; zero the accumulator so it's empty for future use
    jsr wait_for_vblank
    jsr disable_rendering

    jsr draw_menu
    jsr draw_menu_attribute  ; the attribute table is basically where all the colour palettes get assigned to regions on the screen

    lda #$c0
    sta scroll_x

    lda #$0
    sta timer

    jsr enable_rendering

menu_loop:
    lda nmi_ready
    bne menu_loop ; if nmi_ready equals anything but 0, this will send us back up to game_loop - nmi_ready will be set to 0 when an NMI has occurred
                  ; when we're not waiting for a non-maskable interrupt (NMI), we can proceed, to give us the most program time possible before the next one

    set nmi_ready, #$01 ; this is a macro! they're a fun thing that ca65 has where it'll replace this with some predefined code - this one, set, is in utils.asm

    ; MENU LOGIC START
    
    ; increment timer for random seeds later
    inc timer

    jsr check_gamepad ; this basically reads the gamepad inputs and sets a bunch of things - more info in gamepad.asm

    ; MENU LOGIC END

    lda gamepad_new_press
    and #%00001000      ; loop unless start button is being pressed
    beq menu_loop

set_seed:
    ; turn timer into two seperate seeds
    lda timer
    sta rand_seed
    eor #%11111111
    sta rand_seed+1

    ; shuffle the seed if it's even - makes things less predictable
    lda rand_seed
    and #%00000001
    bne skip_lo_seed_shuffle
        lda rand_seed
        rol
        rol
        rol
        rol
        eor #%11111111
        sta rand_seed
    
    skip_lo_seed_shuffle:

    lda rand_seed+1
    and #%00000001
    bne skip_hi_seed_shuffle
        lda rand_seed+1
        rol
        rol
        rol
        rol
        eor #%11111111
        sta rand_seed+1
    
    skip_hi_seed_shuffle:

    lda rand_seed
    cmp #$0
    bne lo_seed_not_zero
    inc rand_seed
    lo_seed_not_zero:

    lda rand_seed+1
    cmp #$0
    bne hi_seed_not_zero
    inc rand_seed+1
    hi_seed_not_zero:

load_level:
    lda #$0 ; zero the accumulator so it's empty for future use
    jsr wait_for_vblank
    jsr disable_rendering

    jsr draw_level
    jsr draw_level_attribute  ; the attribute table is basically where all the colour palettes get assigned to regions on the screen
    jsr load_sprites

place_mines:
    ldy #$28 ; the number of mines we want to place - 40 in decimal

    try_place:
        sty y_mem ; following function clobbers y, so we have to save it for now
        jsr get_rand ; pick a random tile
        ldy y_mem

        get_address_from_acc
        get_tile y_mem, x_mem
        cmp #$11 ; if that tile is a mine already, pick another
        beq try_place
    draw_tile_directly #$11, y_mem, x_mem ; otherwise, draw a hidden mine tile...
    dey ; ...decrement y...
    bne try_place ; ...and return to the top of the loop

    lda #$ff
    sta tile_array_index
    sta draw_tile_index

    sta flags_placed_last

    lda #$0
    sta sprite_to_move

    jsr enable_rendering

game_loop:
    lda nmi_ready
    bne game_loop ; if nmi_ready equals anything but 0, this will send us back up to game_loop - nmi_ready will be set to 0 when an NMI has occurred
                  ; when we're not waiting for a non-maskable interrupt (NMI), we can proceed, to give us the most program time possible before the next one

    set nmi_ready, #$01 ; this is a macro! they're a fun thing that ca65 has where it'll replace this with some predefined code - this one, set, is in utils.asm

    jsr disable_rendering

    ; GAME LOGIC START

    ; if there are tiles to evaluate, no input should be allowed
    lda tile_array_index
    cmp #$ff
    bne skip_button_logic

        lda win_flag ; check if the player has already won
        bne :+
            lda flags_placed ; then, if 40 flags are placed, check if they're all on the correct squares
            cmp #40
            bne :+
                jsr check_flags_for_mines
                tya
                cmp #40
                bne :+
                    sta win_flag
                    lda #$24
                    jsr draw_face
                    jmp skip_tile_eval

        :

        lda lose_flag ; check if the player has potentially lost
        beq :+
            cmp #$01
            bne :+
                inc lose_flag
                jsr explode_mines
                lda #$26
                jsr draw_face
                jmp skip_tile_eval

        :
        jsr check_gamepad ; this basically reads the gamepad inputs and sets a bunch of things - more info in gamepad.asm

        lda win_flag
        bne game_end_controls
        lda lose_flag
        cmp #$02
        beq game_end_controls
            
        jsr button_logic
        jmp :+

        game_end_controls:
            lda gamepad_new_press
            and #%00001111      ; restart when start, select, A, or B button has been pressed
            beq :+
                jmp reset

        :
        ; but, if input did happen, that means there are no tiles to evaluate and we can skip that entirely
        jmp skip_tile_eval

    skip_button_logic:
    jsr evaluate_tile

    skip_tile_eval:

    ; GAME LOGIC END

    set PPU_SCROLL, scroll_x ; horizontal scroll
    set PPU_SCROLL, #0 ; vertical scroll

    jsr enable_rendering
    
    jmp game_loop
