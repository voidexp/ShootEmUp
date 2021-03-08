; ENTITY_TYPES:
ENTITY_PROJECTILE                           = 0
ENTITY_ENEMY_SMALL                          = 1
ENTITY_ENEMY_BIG                            = 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COMPONENT_MASK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 0         - MOVEMENT
; 1         - SPRITE
; 2         - COLLISION
; 3         - HEALTH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; entity:
;    .byte posX, posY
;    .byte component_mask
;    .byte component_list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "RAM"
entity_container:       .res 100             ; contains .. entities
num_current_entities:   .res 1

.code
initialize_entities:
    lda #$00
    sta num_current_entities
    sta init_movement_components
    sta init_sprite_components
    sta init_projectile_components
    rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creates the entity by calculating the storage address of the entity, setting
; the position, mask
;
; ARGS:
;  var_1                - posX
;  var_2                - posY
;  var_3                - component mask
;
; RETURN:
;   address_1           - address of the entity config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
create_entity:   
    jsr get_current_entity_buffer_offset    ; (None -> var_4: address offset)

    calc_address_with_offset entity_container, var_4, address_1

    ldy #$00
    lda var_1
    sta (address_1), Y
    iny

    lda var_2
    sta (address_1), Y
    iny

    lda var_3
    sta (address_1), y
    iny

    inc num_current_entities

    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; returns entity offset for a given entity idop
; ARGS:
;  None
;
; RETURN:
;   var_4           - address of the entity config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_current_entity_buffer_offset:
; get entity component mask and calculate the number of components
; number of components => number of address bytes

    ldx num_current_entities
    ; first 2 bytes of the entity are the position, offset 2 for mask

    lda #<entity_container
    sta address_1

    lda #>entity_container
    sta address_1 + 1

    ldy #$00

    ;check if there are even entities there yet, otherwise return 0
    cpx #$00
    beq end
@entity_loop:
    iny 
    iny                                     ; hop over position storage space
    lda (address_1), Y                      ; get component mask
    sta var_3

    tya
    pha                                     ; push y on stack

    get_num_of_bits_set_in_mask var_3, var_4  ; get amount of components for this entity

    mult_with_constant var_4, #2, var_5     ; size of components buffer for this entity (2 bytes per component)

    pla                                     ; get y from stack

    clc 
    adc var_5                               ; add the offset of the component addresses
    tay

    dex
    cpx #$00
    bne @entity_loop
    iny                                     ;increase offset to new free byte
end:
    tya 
    sta var_4                               ; y -> current offset .. save it and go back
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creates the entity by calculating the storage address of the entity, setting
; the position, mask
;
; ARGS:
;  var_1                - posX
;  var_2                - posY
;  var_3                - component mask
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_entity_position:
    lda #<entity_container
    sta address_1

    lda #>entity_container
    sta address_1 + 1

    ldy #$00
    lda var_1
    sta (address_1), Y
    iny

    lda var_2
    sta (address_1), Y
    iny

    rts