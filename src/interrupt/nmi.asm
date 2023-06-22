.segment "ZEROPAGE"
    nmi_ready: .res 1
    palette_init: .res 1
    scroll_x: .res 1
    tile_ID: .res 1
    screen_pointer: .res 1
    sprite_logger: .res 8
    cursor_x: .res 1
    cursor_y: .res 1
    x_mem: .res 1
    y_mem: .res 1
    x_coord_mem: .res 1
    y_coord_mem: .res 1
    rand_seed: .res 2
    timer: .res 1
    inter: .res 1
    leapfrog: .res 1
    tile_array: .res 140 ; the maximun number of tiles we would ever need to search is 28,
                         ; and each tile needs an x (1st bit) and y(2nd bit) value to be stored to be evaluated
    tile_array_index: .res 1 ; number of tiles in tile_array * 2 (starts at #$ff because it's an offset, so we want the first tile to be at address 0)
    jsr_indirect_address: .res 2
    dupe_flag: .res 1
    tiles_to_draw: .res 45 ; tile to be drawn next frame, ID(1st bit), LO(2nd bit), HI(3rd bit)
    draw_tile_index: .res 1 ; number of tiles in tiles_to_draw * 3 (starts at #$ff because it's an offset, so we want the first tile to be at address 0)

.segment "CODE"

nmi:
    pha             ; make sure we don't clobber the A register

    lda nmi_ready   ; check the nmi_ready flag
    bne nmi_go      ; if nmi_ready set to 1 we can execute the nmi code
        pla
        rti
    nmi_go:

    lda draw_tile_index
    cmp #$ff
    beq :+
        jsr nmi_load_tile

    :
    set PPU_SCROLL, scroll_x ; horizontal scroll
    set PPU_SCROLL, #0 ; vertical scroll

    jsr enable_rendering

    ; set the cursor metasprite with a proc
    jsr update_cursor_sprite

    lda PPU_STATUS ; $2002

    ; initialise render
    jsr oam_dma

    set nmi_ready, #0

    pla
    rti
