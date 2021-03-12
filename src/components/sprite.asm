.rodata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; sprite component:
;    .addr owner                     ; entity
;    .addr sprite config
;    .byte animation_frame
; movement rule
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPRITE_COMP_SIZE = 5

.segment "RAM"
sprite_component_container: .res 150

num_sprite_components: .res 1

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_sprite_components:
    lda #$00
    sta num_sprite_components
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create sprite components
; ARGS:
;   address_1           - owner
;   address_2           - sprite_config
;
; RETURN:
;   address_3           - address of sprite_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
create_sprite_component:
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; update sprite animation
; get the length of the animation and either increase/reset current frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_sprite_components:
    ;lda update_animations
    ;cmp #ANIMATION_SPEED
    ;bpl end_of_anims                        ; should we tick anims? - if not return to end ... else tick!

    lda #<sprite_component_container
    sta address_1

    lda #>sprite_component_container
    sta address_1 + 1

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
draw_sprite_components:
    lda #<sprite_component_container
    sta address_1

    lda #>sprite_component_container
    sta address_1 + 1

    lda num_sprite_components
    sta var_10
    tya
    tax                                     ; oam_offset to x


    ldy #$00                                ; reset y
    
    lda num_sprite_components
    cmp #$00
    bne  @process_sprite_object         ; early out if list is empty
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

    ; get the address of the object animation setting
    ; TODO: extend with choosing anim according to state
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

    ; if component is disabled set tile_id to something invisible
    lda #SPRITE_CMP
    bit var_9
    bne :+

    lda #$0c
    sta var_7


:   iny
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
    jmp @process_sprite_object

:   txa
    tay                                     ; oam offset from x to y
    rts