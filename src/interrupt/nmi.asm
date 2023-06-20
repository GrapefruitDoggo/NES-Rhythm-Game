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
    rand_seed: .res 2
    timer: .res 1

.segment "CODE"

nmi:
    pha             ; make sure we don't clobber the A register

    lda nmi_ready   ; check the nmi_ready flag
    bne nmi_go      ; if nmi_ready set to 1 we can execute the nmi code
        pla
        rti
    nmi_go:

    ; set the cursor metasprite with a proc
    jsr update_cursor_sprite

    lda PPU_STATUS ; $2002

    set PPU_SCROLL, scroll_x ; horizontal scroll
    set PPU_SCROLL, #0 ; vertical scroll

    ; initialise render
    jsr oam_dma

    set nmi_ready, #0

    pla
    rti
