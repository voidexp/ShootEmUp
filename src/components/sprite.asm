.include "constants.asm"
.include "globals.asm"
.include "macros.asm"
.include "nes.asm"

.export init_sprite_components
.export create_sprite_component
.export draw_sprite_components
.export update_sprite_components

.rodata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite component:
;    .addr owner                     ; entity
;    .addr sprite config
;    .byte animation_frame
; movement rule
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPRITE_COMP_SIZE = 5
; ANIMATION_SPEED = 8

.segment "BSS"
sprite_component_container: .res 250

num_sprite_components:      .res 1
num_drawn_sprites:          .res 1

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc init_sprite_components
    lda #$00
    sta num_sprite_components
    sta num_drawn_sprites
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create sprite components
; ARGS:
;   address_1           - owner
;   address_2           - sprite_config
;
; RETURN:
;   address_3           - address of sprite_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_sprite_component
    ; calculate offset in current component buffer
    mult_with_constant num_sprite_components, #SPRITE_COMP_SIZE, var_1

    calc_address_with_offset sprite_component_container, var_1, address_3 ;address_3 is return address

    ldy #$00                                ; owner lo
    lda address_1
    sta (address_3), y

    iny
    lda address_1 + 1                        ; owner hi
    sta (address_3), y
    iny

    lda address_2                           ; sprite address lo
    sta (address_3), y
    iny

    lda address_2 + 1                       ; sprite address hi
    sta (address_3), y
    iny

    lda #$00                                ; current anim frame
    sta (address_3), Y

    inc num_sprite_components
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; update sprite animation
; get the length of the animation and either increase/reset current frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_sprite_components
    ;lda update_animations
    ;cmp #ANIMATION_SPEED
    ;bpl end_of_anims                        ; should we tick anims? - if not return to end ... else tick!

    lda #<sprite_component_container
    sta address_1

    lda #>sprite_component_container
    sta address_1 + 1

    ldy #$45
    ldy #$00
    lda num_sprite_components
    sta var_1

    cmp #$00
    bne @tick_sprite                        ; early out if list is empty
    rts
@tick_sprite:
    iny                                     ; ignore owner address
    iny

    lda (address_1), y                      ; Get sprite config lo byte
    sta address_2
    iny

    lda (address_1), y                      ; Get sprite config hi byte
    sta address_2 + 1
    iny

    ;iny                                    ; we don't have posX and posY in this component
    ;iny                                    ; pos-x and pos-y are on 2nd and 3rd place

    lda (address_1), y                      ; animation frame
    sta var_2

    tya
    pha ; push y on hw stack

    jsr update_animation                    ; (var_2, address_2 => var_2)

    pla                                     ; pull y from hw stack
    tay
    lda var_2
    sta (address_1), y
    iny

    dec var_1                               ; check if there are enemies left to draw
    lda var_1
    cmp #$00
    beq :+
    jmp @tick_sprite
:
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DRAW SPRITE ANIMATION COMPONENTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ARGS:
; y                     - oam offset
;
; RETURN:
; y                      - oam offset
;
; USES
;; tile_data:
; var_5                 - posX
; var_6                 - posy
; var_7                 - tileID
; var_8                 - attribute id
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Example of sprite animation setting
; squady_idle_animation:
;    .byte $04                               ; length frames
;    .byte $08                               ; speed
;    .byte $20                               ; starting tile ID
;    .byte $02                               ; attribute set
;    .byte $01                               ; padding x, z -> 1 tiles wide and high
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc draw_sprite_components
    lda #<sprite_component_container
    sta address_1

    lda #>sprite_component_container
    sta address_1 + 1

    lda #$00
    sta num_drawn_sprites

    lda num_sprite_components               ; #NUM_SPRITES
    sta var_10
    tya
    tax                                     ; oam_offset to x

    ldy #$00                                ; reset y

    lda num_sprite_components
    cmp #$00
    bne @process_sprite_object         ; early out if list is empty
    txa
    tay                                     ; oam offset from x to y
    rts
@process_sprite_object:
    lda (address_1), y                      ; Get entity address lo byte
    sta address_2
    iny
    lda (address_1), y                      ; Get entity address hi byte
    sta address_2 + 1
    iny

    tya                                     ; push y to stack
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (address_2), y
    sta var_5
    iny

    lda (address_2), y
    sta var_6

    iny
    iny
    lda (address_2), Y                      ; get mask of active components
    sta var_9

    pla                                     ; get y offset from stack again
    tay

     ; if component is disabled go to the next sprite component
    lda #SPRITE_CMP
    bit var_9
    bne :+
    iny                                     ; set the correct offset to the next sprite component
    iny
    iny
    jmp @check_for_more_sprite_components
:
    ; get the address of the object animation setting
    lda (address_1), Y
    sta address_3
    iny

    lda (address_1), Y
    sta address_3 + 1
    iny

    lda (address_1), y                      ; animation frame
    sta var_4
    iny

    tya
    pha                                     ; sprite component buffer offset to stack

    ; Hi future: if you ever reconsider ticking the animation in the draw loop, do it here
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

    ; if component is disabled set tile_id to something invisible
    ;lda #SPRITE_CMP
    ;bit var_9
    ;bne :+

    ;lda #$0c
    ;sta var_7

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

@check_for_more_sprite_components:
    dec var_10                              ; check if there are sprite components left to draw
    lda var_10
    cmp #$00
    beq :+
    jmp @process_sprite_object

:
    txa
    tay                                     ; oam offset from x to y
    jmp draw_empty_objects
    rts
.endproc


.proc draw_empty_objects
    ; take empty sprite id and set it to the id of all remaining empty sprites
@empty_sprite_loop:
    lda num_drawn_sprites
    cmp #NUM_SPRITES
    bcs @back_to_main_loop

    iny
    lda #$0c
    sta oam, Y                              ; just overwrite tile id
    iny
    iny
    iny

    inc num_drawn_sprites
    jmp @empty_sprite_loop
@back_to_main_loop:
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
