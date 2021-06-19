.export update_animation
.export draw_object


.rodata
ANIMATION_SPEED = 8


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; tick enemy animations
; ARGS:
; var_2                 - current current animation frame
; address_2             - animation config
;
; RETURN:
; var_2                 - updated anim frame
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; get current frame
; increase current frame
; if current frame exceeds bounds reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_animation
    inc var_2                               ; increase anim frame

    ;ldy #$00
    ;lda (address_2), Y
    ;sta address_3
    ;iny
    ;lda (address_2), Y
    ;sta address_3 + 1

    ldy #$00                                ; 00 is anim length
    lda (address_2), Y                      ; load anim length

    cmp var_2

    bne :+
    lda #$00
    sta var_2
:
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DRAW OBJECT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ARGS:
; x                     - oam offset
; var_2                 - width/height of object
;
; base_tile_data:
; var_5                 - pos x
; var_6                 - pos y
; var_7                 - tile id
; var_8                 - attribute id
;
; address_1             - animation config
;
; RETURN:
; x                     - updated oam offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Takes width/height of the object and calculates correct positions for all
; for the separate tiles of the object
; Result: all required tiles are saved in the shadow oam
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc draw_object
    lda var_2                               ; we use var_2 for heigth, var_1 for width
    dec var_2
    lda var_2
    sta var_1                               ; store width on var_3 for height (atm everything is square)
    pha                                     ; and push it to stack .. we need it later again

    lda var_2
    ; shifted y offset
    ; offset to one tile in y axis means + 10 row so
    asl
    asl
    asl
    asl
    sta var_3                               ; offset for tile id

    ; now draw all associated tiles for this object
    ; we start with the bottom y row

    txa                                    ; move oam offset from x to y
    tay

@draw_tiles_loop:
    jsr draw_tile
    ; check if we have drawn all x tiles
    lda var_1                               ; remaining tiles in x axis
    cmp #$00
    beq :+
    dec var_1
    jmp @draw_tiles_loop
:   lda var_2                               ; remaining tiles in y axis
    cmp #$00
    beq @epic_end                           ; if we have reached the last y tile let's stop drawing tiles
    pla                                     ; get original width from stack
    sta var_1
    pha
    dec var_2
    lda var_3
    sec
    sbc #$10
    sta var_3
    jmp @draw_tiles_loop
@epic_end:                                  ; epic return
    tya                                     ; oam offset from y to x again
    tax

    pla
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw simple sprite tile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ARGS:
; y                     - oam offset
; var_1                 - x offset
; var_2                 - y offset
; var_3                 - shifted y offset (instead of 01 .. 10)
; var_5                 - pos x
; var_6                 - pos y
; var_7                 - tile id
; var_8                 - attribute id
;
; RETURN:
; y                     - update oam offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; move offset calculation to draw_object?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc draw_tile

    mult_with_constant var_2, #PIXELS_PER_TILE, var_4

    lda var_6
    clc
    adc var_4                              ; y offset
    sta oam, Y
    iny

    lda var_7                               ; tile id
    clc
    adc var_1
    adc var_3                               ; y offset (shifted version of temp2)
    sta oam, y
    iny

    lda var_8                               ; attribute id
    sta oam, Y
    iny

    mult_with_constant var_1, #PIXELS_PER_TILE, var_4

    lda var_5                               ; set x position
    clc
    adc var_4                               ; add x offset
    sta oam, y
    iny

    inc num_drawn_sprites
    rts
.endproc
