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

; this code draws a single background tile to the screen!
.macro draw_tile ID, HI, LO

    lda PPU_STATUS        ; PPU_STATUS = $2002

    ; here we're telling the ppu where on the screen to put the tile we're about to give it - first the hi bit (say $20), then the lo bit (say, $21)
    ; which forms the two-bit address $2021 :3
    lda HI
    sta PPU_ADDR          ; PPU_ADDR = $2006
    lda LO
    sta PPU_ADDR

    ; we need to set the scroll after accessing PPU_STATUS, since doing that resets scroll back to $0 for some reason
    set PPU_SCROLL, scroll_x ; horizontal scroll
    set PPU_SCROLL, #0 ; vertical scroll

    lda ID  ; the id of the tile we want to draw - each 8x8 pixel square on a tilesheet counts as one 'id' in this system
    sta PPU_DATA
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

    ; we need to set the scroll after accessing PPU_STATUS, since doing that resets scroll back to $0 for some reason
    set PPU_SCROLL, scroll_x ; horizontal scroll
    set PPU_SCROLL, #0 ; vertical scroll

    lda PPU_DATA
    lda PPU_DATA  ; the id of the tile we are looking at
.endmacro

; gets tile coordinates from the number in the accumulator
.macro get_coords_from_acc

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
        lda level_attribute, x
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
.proc check_mine
    get_tile y_mem, x_mem
    cmp #$01
    bne no_mine ; if the tile isn't ID $01, then there's no mine there. Otherwise...
    draw_tile #$9c, y_mem, x_mem ; for now, this sets the tile to M. Later, it will end the game (explosion)
    rts

    no_mine:
    draw_tile #$11, y_mem, x_mem
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

    jsr check_mine

    jmp a_done

b_press:
    jsr find_cursor

    draw_tile #$01, y_mem, x_mem

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