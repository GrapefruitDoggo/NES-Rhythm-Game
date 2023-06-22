.segment "CODE"

; this is basically an x = y, or in this case target = source
.macro set target, source
    lda source
    sta target
.endmacro

; this procedure will loop until the next vblank
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

.proc nmi_load_tile

    lda PPU_STATUS        ; PPU_STATUS = $2002

    ldx draw_tile_index
    lda tiles_to_draw, x
    sta PPU_ADDR
    lda #$0
    sta tiles_to_draw, x
    dex
    lda tiles_to_draw, x
    sta PPU_ADDR
    lda #$0
    sta tiles_to_draw, x
    dex

    lda tiles_to_draw, x
    sta PPU_DATA
    lda #$0
    sta tiles_to_draw, x
    dex
    
    stx draw_tile_index

.endproc

.macro draw_tile_directly ID, HI, LO

    lda PPU_STATUS        ; PPU_STATUS = $2002

    ; here we're telling the ppu where on the screen to find the tile we want info about - first the hi bit (say $20), then the lo bit (say, $21)
    ; which forms the two-bit address $2021 :3
    lda HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda LO
    sta PPU_ADDR

    lda ID
    sta PPU_DATA  ; the id of the tile we want to set
    
.endmacro

; this code draws a single background tile to the screen!
.macro draw_tile ID, HI, LO

    inc draw_tile_index
    ldx draw_tile_index
    lda ID  ; the id of the tile we want to draw - each 8x8 pixel square on a tilesheet counts as one 'id' in this system
    sta tiles_to_draw, x

    inc draw_tile_index
    ldx draw_tile_index
    lda LO
    sta tiles_to_draw, x

    inc draw_tile_index
    ldx draw_tile_index
    lda HI
    sta tiles_to_draw, x
    
.endmacro

; this code retrieves the ID at 
.macro get_tile HI, LO
    
    lda PPU_STATUS        ; PPU_STATUS = $2002

    ; here we're telling the ppu where on the screen to find the tile we want info about - first the hi bit (say $20), then the lo bit (say, $21)
    ; which forms the two-bit address $2021 :3
    lda HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda LO
    sta PPU_ADDR

    lda PPU_DATA
    lda PPU_DATA  ; the id of the tile we are looking at
.endmacro

; gets tile coordinates from the number in the accumulator
.macro get_address_from_acc

    sta y_mem

    ; find X coord
    and #%00001111 ; modulo 16
    sta x_mem

    ; find Y coord
    lda y_mem
    divide_acc_by_16
    sta y_mem

    ; following is based on find_cursor
    asl
    asl
    asl
    asl
    asl
    clc

    adc x_mem
    adc #$20
    sta x_mem

    lda y_mem
    lsr
    lsr
    lsr
    tax

    lda x_mem
    and #%11110000
    beq skip_clear_carry_2
        clc

    skip_clear_carry_2:
    txa
    adc #$21
    sta y_mem
.endmacro

.macro get_address_from_coords x_loc, y_loc

    lda y_loc

    ; following is based on find_cursor
    asl
    asl
    asl
    asl
    asl
    clc

    adc x_loc
    adc #$20
    sta x_mem

    lda y_loc
    lsr
    lsr
    lsr
    tax

    lda x_mem
    and #%11110000
    beq skip_clear_carry_2
        clc

    skip_clear_carry_2:
    txa
    adc #$21
    sta y_mem
.endmacro

.macro do_proc_on_surrounding_8_tiles PROC_HI, PROC_LO
    lda PROC_HI
    sta jsr_indirect_address
    lda PROC_LO
    sta jsr_indirect_address+1

    ; jsr_indirect will send us to the point just after the address we entered, so we need to decrement it by 1 first
    lda jsr_indirect_address+1
    cmp #$0
    bne :+ ; if jsr_indirect_address+1 is 0, decrement jsr_indirect_address by 1 as well
        dec jsr_indirect_address

    :
    dec jsr_indirect_address+1

    jsr do_proc_on_surrounding_8_tiles_logic
.endmacro

.macro do_proc_on_surrounding_4_tiles PROC_HI, PROC_LO
    lda PROC_HI
    sta jsr_indirect_address
    lda PROC_LO
    sta jsr_indirect_address+1

    ; jsr_indirect will send us to the point just after the address we entered, so we need to decrement it by 1 first
    lda jsr_indirect_address+1
    cmp #$0
    bne :+ ; if jsr_indirect_address+1 is 0, decrement jsr_indirect_address by 1 as well
        dec jsr_indirect_address

    :
    dec jsr_indirect_address+1

    jsr do_proc_on_surrounding_4_tiles_logic
.endmacro

; gets a random number from the seed, and outputs the result in the a register
.proc get_rand

    ldy #$8 ; we iterate over the following code 8 times, randomising one bit each time
    lda rand_seed ; load the LSB of the seed

    rand_loop:
    asl ; shift rand lo bit left
    rol rand_seed+1 ; shift rand hi bit left
    bcc skip_xor
    eor #$39

    skip_xor:
    dey
    bne rand_loop ; loop end
    sta rand_seed ; store a in the seed memory address
    cmp #$0 ; resets relevant flags

    rts
.endproc

; find cursor position on background
.proc find_cursor

    lda cursor_y

    asl
    asl
    asl
    asl
    asl
    clc
    adc cursor_x
    adc #$20
    sta x_mem

    lda cursor_y
    lsr
    lsr
    lsr
    tax

    lda x_mem
    and #%11110000
    beq skip_clear_carry
        clc

    skip_clear_carry:
    txa
    adc #$21
    sta y_mem
    rts
.endproc

; this code runs at the start of the game and basically copies everything from level.asm to ppu memory - initialising the gameboard essentially
; it's basically just draw_tile a bunch, but split into 4 seperate loops.
.proc draw_level
    ; bytes 0-255
    ldy #$20
    ldx #$00

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    level_render_loop_1:
        lda level, x
        sta PPU_DATA

        inx
        bne level_render_loop_1

    ldy #$21

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    level_render_loop_2:
        lda level+$0100, x
        sta PPU_DATA

        inx
        bne level_render_loop_2

    ldy #$22
    
    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    level_render_loop_3:
        lda level+$0200, x
        sta PPU_DATA

        inx
        bne level_render_loop_3

    ldy #$23
    
    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    ; the final loop has a few less bytes to load
    level_render_loop_4:
        lda level+$0300, x
        sta PPU_DATA

        inx
        cpx #$bf
        bne level_render_loop_4
    rts
.endproc

; like draw_level, but for the attribute table - much shorter, cos there's a lot less data to transfer
.proc draw_level_attribute
    lda PPU_STATUS        ; PPU_STATUS = $2002

    lda #$23
    sta PPU_ADDR          ; High byte
    lda #$c0
    sta PPU_ADDR          ; Low byte

    ldx #$00

    level_attribute_loop_1:
        lda level_attribute, x
        sta PPU_DATA

        inx
        cpx #$40
        bne level_attribute_loop_1
    rts
.endproc

.proc draw_menu
    ; bytes 0-255
    ldy #$20
    ldx #$00

    lda PPU_STATUS        ; PPU_STATUS = $2002

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    menu_render_loop_1:
        lda menu, x
        sta PPU_DATA

        inx
        bne menu_render_loop_1

    ldy #$21

    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    menu_render_loop_2:
        lda menu+$0100, x
        sta PPU_DATA

        inx
        bne menu_render_loop_2

    ldy #$22
    
    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    menu_render_loop_3:
        lda menu+$0200, x
        sta PPU_DATA

        inx
        bne menu_render_loop_3

    ldy #$23
    
    sty PPU_ADDR          ; High byte
    stx PPU_ADDR          ; Low byte

    ; the final loop has a few less bytes to load
    menu_render_loop_4:
        lda menu+$0300, x
        sta PPU_DATA

        inx
        cpx #$bf
        bne menu_render_loop_4
    rts
.endproc

.proc draw_menu_attribute
    lda PPU_STATUS        ; PPU_STATUS = $2002

    lda #$23
    sta PPU_ADDR          ; High byte
    lda #$c0
    sta PPU_ADDR          ; Low byte

    ldx #$00

    attribute_loop_1:
        lda menu_attribute, x
        sta PPU_DATA

        inx
        cpx #$40
        bne attribute_loop_1
    rts
.endproc

; this loads all the sprites in sprites.asm. this is to save having to spawn in (and keep track of) new ones later, which would take up already sparse resources
.proc load_sprites
    ldx #$00

loadsprites:
    lda sprites, x      ; accesses each sprite in sprites (defined in sprites.asm) starting at index 0
    sta $0200, x        ; store in sprite memory location
    inx
    cpx #$A4            ; each sprite holds 4 bytes of data - Ycoord, tile, attributes and Xcoord - and there are 41 sprites, so 4*41 = 164, or $A4
    bne loadsprites
    rts
.endproc

; call this only after a recent find_cursor!!!
.proc check_tile_for_mine
    get_tile y_mem, x_mem
    cmp #$11
    bne no_mine ; if the tile isn't ID $01, then there's no mine there. Otherwise...
        draw_tile #$9c, y_mem, x_mem ; for now, this sets the tile to M. Later, it will end the game (explosion)
        rts

    no_mine:
    jsr tile_search
    rts
.endproc

.proc count_mine
    get_address_from_coords x_coord_mem, y_coord_mem
    get_tile y_mem, x_mem
    cmp #$11
    bne skip_count_mine
        iny
    skip_count_mine:
    rts
.endproc

.proc check_tile_table_for_duplicates
    lda tile_array_index
    cmp #$ff
    beq skip_check_dupes
        ldx tile_array_index
        check_dupes_loop:
            ; reset dupe flag
            lda #$0
            sta dupe_flag

            ; odd, y coord
            lda y_coord_mem
            cmp tile_array, x
            bne :+
                inc dupe_flag

            :
            dex
            ; even, x coord
            lda x_coord_mem
            cmp tile_array, x
            bne :+
                inc dupe_flag

            :
            lda dupe_flag
            cmp #$2 ; if we've found a dupe, exit the loop
            bne :+
                rts

            :
            dex
            txa
            cmp #$ff
            bne check_dupes_loop
    skip_check_dupes:
    rts
.endproc

.proc store_tile_in_table
    jsr check_tile_table_for_duplicates
    lda dupe_flag
    cmp #$2
    beq :+
        ; put the tile's two-byte coordinates into the table so we can assess them next frame
        inc tile_array_index
        lda x_coord_mem
        ldx tile_array_index
        sta tile_array, x

        inc tile_array_index
        lda y_coord_mem
        ldx tile_array_index
        sta tile_array, x

    :

    ; reset dupe flag
    lda #$0
    sta dupe_flag
    rts
.endproc

; simulated jsr to a location specified in code
; set jsr_indirect_address before using
.proc jsr_indirect
    ; we perform some magic and trick the processor into thinking we came from the place we want to go "back" to
    lda jsr_indirect_address
    pha
    lda jsr_indirect_address+1
    pha
    rts
.endproc

; set x_ and y_coord_mem before using
; set jsr_indirect_address before using
.proc do_proc_on_surrounding_8_tiles_logic
    dec y_coord_mem ; top
    lda y_coord_mem
    cmp #$ff  ; if y_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    dec x_coord_mem ; top left
    lda x_coord_mem
    cmp #$ff ; if x_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
    lda y_coord_mem
    cmp #$ff ; if x_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc y_coord_mem ; left
    lda x_coord_mem
    cmp #$ff ; if x_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc y_coord_mem ; bottom left
    lda y_coord_mem
    cmp #$10 ; if y_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
    lda x_coord_mem
    cmp #$ff ; if x_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc x_coord_mem ; bottom
    lda y_coord_mem
    cmp #$10 ; if y_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc x_coord_mem ; bottom right
    lda x_coord_mem
    cmp #$10 ; if x_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
    lda y_coord_mem
    cmp #$10 ; if y_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    dec y_coord_mem ; right
    lda x_coord_mem
    cmp #$10 ; if x_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    dec y_coord_mem ; top right
    lda y_coord_mem
    cmp #$ff ; if y_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
    lda x_coord_mem
    cmp #$10 ; if x_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    ; then, we reset coord_mem and mem variables
    dec x_coord_mem
    inc y_coord_mem
    get_address_from_coords x_coord_mem, y_coord_mem
    rts
.endproc

.proc do_proc_on_surrounding_4_tiles_logic
    dec y_coord_mem ; top
    lda y_coord_mem
    cmp #$ff  ; if y_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    dec x_coord_mem
    inc y_coord_mem ; left
    lda x_coord_mem
    cmp #$ff ; if x_coord_mem is ff, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc y_coord_mem
    inc x_coord_mem ; bottom
    lda y_coord_mem
    cmp #$10 ; if y_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    inc x_coord_mem
    dec y_coord_mem ; right
    lda x_coord_mem
    cmp #$10 ; if x_coord_mem is 10, it isn't on the board, so we skip counting whatever it's pointing to
    beq :+
        jsr jsr_indirect

    :
    ; then, we reset coord_mem and mem variables
    dec x_coord_mem
    get_address_from_coords x_coord_mem, y_coord_mem
    rts
.endproc

.proc tile_search
    get_tile y_mem, x_mem
    sta leapfrog
    cmp #$10
    bne not_a_hidden_tile ; if the tile id is not 10, then we can skip it, as it's not a tile we care about
        ; otherwise, look at all the tiles surrounding this one and count how many are mines
        ldy #$0
        lda cursor_x
        sta x_coord_mem
        lda cursor_y
        sta y_coord_mem

        ; do_proc_on_surrounding_8_tiles using count_mine
        do_proc_on_surrounding_8_tiles #>count_mine, #<count_mine

        ; if there are no mines, then we'll need to search the surrounding tiles
        ; do_proc_on_surrounding_4_tiles using store_tile_in_table
        tya
        cmp #$0
        bne skip_store_tile
            do_proc_on_surrounding_4_tiles #>store_tile_in_table, #<store_tile_in_table

        skip_store_tile:

        ; finally, we draw a tile with an offset equal to the number of mines
        tya
        clc
        adc #$40
        sta inter
        draw_tile inter, y_mem, x_mem

    not_a_hidden_tile:
    rts
.endproc

.proc evaluate_tile
    ldx tile_array_index
    lda tile_array, x
    sta y_coord_mem
    lda #$0
    sta tile_array, x
    dec tile_array_index

    ldx tile_array_index
    lda tile_array, x
    sta x_coord_mem
    lda #$0
    sta tile_array, x
    dec tile_array_index

    get_address_from_coords x_coord_mem, y_coord_mem
    get_tile y_mem, x_mem
    cmp #$10
    bne eval_not_a_hidden_tile ; if the tile id is not 10, then we can skip it, as it's no longer a tile we care about
        ldy #$0
        ; do_proc_on_surrounding_8_tiles using count_mine
        do_proc_on_surrounding_8_tiles #>count_mine, #<count_mine

        ; if there are no mines, then we'll need to search the surrounding tiles
        ; do_proc_on_surrounding_4_tiles using store_tile_in_table
        tya
        cmp #$0
        bne skip_store_tile
            do_proc_on_surrounding_4_tiles #>store_tile_in_table, #<store_tile_in_table

        skip_store_tile:

        ; finally, we draw a tile with an offset equal to the number of mines
        tya
        clc
        adc #$40
        sta inter
        draw_tile inter, y_mem, x_mem

    eval_not_a_hidden_tile:
    rts
.endproc

.proc button_logic
    lda gamepad_new_press
    and #%01000000      ; if left button is being pressed...
    bne left_press      ; do stuff at the left_press label
left_done:
    lda gamepad_new_press
    and #%10000000      ; above, but right
    bne right_press
right_done:
    lda gamepad_new_press
    and #%00010000      ; above, but up
    bne up_press
up_done:
    lda gamepad_new_press
    and #%00100000      ; above, but down
    bne down_press
down_done:
    lda gamepad_new_press
    and #%00000001      ; above, but a
    bne a_press
a_done:
    lda gamepad_new_press
    and #%00000010      ; above, but b
    bne b_press
b_done:
    rts                 ; if nothing's being pressed, go back to the program

left_press:
    sec
    lda cursor_x
    sbc #$01
    sta cursor_x
    jmp left_done

right_press:
    clc
    lda cursor_x
    adc #$01
    sta cursor_x
    jmp right_done

up_press:
    sec
    lda cursor_y
    sbc #$01
    sta cursor_y
    jmp up_done

down_press:
    clc
    lda cursor_y
    adc #$01
    sta cursor_y
    jmp down_done

a_press:
    jsr find_cursor

    jsr check_tile_for_mine

    jmp a_done

b_press:
    jsr find_cursor

    draw_tile #$11, y_mem, x_mem

    jmp b_done
.endproc

.proc update_cursor_sprite
    lda cursor_y
    cmp #$ff
    bne no_top_warp
        lda #$0f
        sta cursor_y
    no_top_warp:
    cmp #$10
    bne no_bottom_warp
        lda #$00
        sta cursor_y
    no_bottom_warp:
    clc

    ; offset of 9 "tiles" to make cursor_y = 0 the topmost tile
    adc #$9

    ; multiply by 8
    asl
    asl
    asl

    ; subtract 1, because for some reason the sprite is one pixel too low
    sec
    sbc #$01
    sta $0200

    lda cursor_x
    cmp #$ff
    bne no_left_warp
        lda #$0f
        sta cursor_x
    no_left_warp:
    cmp #$10
    bne no_right_warp
        lda #$00
        sta cursor_x
    no_right_warp:
    clc

    ; offset of 8 "tiles" to make cursor_x = 0 the leftmost tile
    adc #$8

    ; multiply by 8
    asl
    asl
    asl
    and #%11111000
    sta $0203
    rts
.endproc