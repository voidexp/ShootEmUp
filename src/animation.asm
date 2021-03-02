.code


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load animation config 
; ARGS:
; var_1                 - Num enemies
; address_1             - Object config
; address_2             - Object pool
;
; RETURN:
; - 
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Stores the animation data in the anim pool in the format:
; 2 byte                - Adress to Anim Config
; 2 byte                - Position
; 1 byte                - Current Animframe
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load_animation_set:
    txa 
    pha

    tya
    pha

    ldy #$00                                ; loading offset
    sty var_2
    sty var_3

    lda #$04
    sta var_4
@load_animation_setting:
    ; copy address of animation setting and initial position to ram buffer
    copy_x_bytes_zp address_1, var_2, address_2, var_3, var_4

    lda var_2
    clc
    adc var_4
    sta var_2

    lda var_3
    clc
    adc var_4
    sta var_3

    ; set initial frame
    ldy var_3
    lda #$00
    sta (address_2), y
    inc var_3

    ; check if there are more enemies to load
    dec var_1
    lda var_1
    cmp #$00
    bne @load_animation_setting

    ; pull virtual stack offset from hw stack
    pla
    tay

    pla
    tax 

    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; update animation set
; ARGS:
; var_1                 - Num enemies
; address_1             - animation pool
;
; RETURN:
; - 
; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; every frame the animation is updated depending on the animation speed
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_animation_set:
    lda update_animations
    cmp #ANIMATION_SPEED
    bpl end_of_anims                        ; should we tick anims? - if not return to end ... else tick!

    ldy #$00
tick_object:
    lda (address_1), y                      ; Get lo byte
	sta address_2
    iny

    lda (address_1), y                      ; Get hi byte
	sta address_2 + 1
    iny

    iny
    iny                                     ; pos-x and pos-y are on 2nd and 3rd place

    lda (address_1), y                      ; animation frame
    sta var_2    

    tya
    pha ; push y on hw stack

    jsr update_animation                    ; (var_2, address_2 => var_2)

    pla                                     ; pull y from hw stack
    tay
    lda var_2
    ;sta (address_1), y
    iny

    dec var_1                              ; check if there are enemies left to draw
    lda var_1
    cmp #$00
    beq end_of_anims
    jmp tick_object
end_of_anims:
    lda #$00
    sta update_animations

    rts


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
update_animation:
    inc var_2                               ; increase anim frame

    ldy #$00
    lda (address_2), Y
    sta address_3
    iny
    lda (address_2), Y
	sta address_3 + 1 

    ldy #$00                                ; 00 is anim length
    lda (address_3), Y                      ; load anim length

    cmp var_2

    bne :+
    lda #$00
    sta var_2
:   
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; draw .. yay
; draw the set of current enemies
; a) go over the enemy buffer
; b) extract current enemy data (position, settings address, size etc)
; c) store current enemy setting in tile data, this data stays the same over the 
;    tile loop
; d) store width, height, and oam offset in virtual stack
; e) call draw_object which iterates over w, h and draws all tiles for this 
;    object
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Draw object animation set
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ARGS:
; y                     - oam offset
; var_1                 - num enemies
; address_1             - animation config
;
; RETURN:
; y                      - oam offset
; 
;; tile_data: var_5, var_6, var_7, var_8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_animation_set:
    lda var_1
    sta var_10
    tya
    tax                                     ; oam_offset to x

    ldy #$00                                ; reset y
@proccess_animation_object:
    lda (address_1), y                      ; Get lo byte
	sta address_2
    iny
    lda (address_1), y                      ; Get hi byte
	sta address_2 + 1
    iny

    lda (address_1), y                      ; xpos
    sta var_5                               ; in tile data
    iny

    lda (address_1), y                      ; ypos
    sta var_6                               ; in tile data
    iny

    lda (address_1), y                      ; animation frame
    lda #$00
    sta var_4
    iny

    tya 
    pha                                     ; animation buffer offset to stack

    ldy #$00
    ; get the address of the object animation setting
    ; TODO: extend with choosing anim according to state
    lda (address_2), Y
    sta address_3
    iny

    lda (address_2), Y
	sta address_3 + 1 

    ; Hi future gabi, if you ever reconsider ticking the animation in the draw loop, do it here

    ; height, length
    ; offset to height and length
    ldy #$04
    lda (address_3), Y
    sta var_2

    mult_variables var_4, var_2, var_3      ; (var_4 X var_2 => var_3) => animation_frame * width (in tiles)

    ; starting tile id -> get current animation frame (length of anim X frame)
    ldy #$02                                ; 00 is length, 01 speed, 02 is tile id :)
    lda (address_3), Y 

    clc
    adc var_3                               ; add multiplied animframe
    sta var_7                               ; tile id

    iny
    lda (address_3), Y 
    sta var_8                               ; attribute
    iny
    ; width and height -> var_2

    lda var_1                               ; to be on the safe side push var_1 on stack
    pha
   
    jsr draw_object

    pla                                     ; stack has var_1 and anim buffer offset 
    sta var_1

    pla                                     ; get animation buffer offset
    tay

    dec var_10                              ; check if there are enemies left to draw
    lda var_10
    cmp #$00
    beq :+
    jmp @proccess_animation_object

:   txa
    tay                                     ; oam offset from x to y
    rts


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
draw_object:
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
draw_tile:

    mult_constant var_2, #PIXELS_PER_TILE, var_4

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

    mult_constant var_1, #PIXELS_PER_TILE, var_4

    lda var_5                               ; set x position
    clc
    adc var_4                               ; add x offset
    sta oam, y
    iny

    rts