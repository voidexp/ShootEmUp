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
MOVEMENT_CMP        = 1
SPRITE_CMP          = 2
COLLISION_CMP       = 4
HEALTH_CMP          = 8
ENEMY_CMP           = 16
ACTOR_CMP           = 32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; entity:
;    .byte posX, posY
;    .byte component_mask
;    .byte active_components_mask
;    .byte component_list
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "BSS"
entity_container:       .res 300             ; contains .. entities
num_current_entities:   .res 1

.code
initialize_entities:
    lda #$00
    sta num_current_entities
    jsr init_movement_components
    jsr init_sprite_components
    jsr init_projectile_components
    jsr init_collision_components 
    jsr init_enemy_components
    jsr init_flame_entities
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
    lda var_3
    pha 

    jsr get_current_entity_buffer_offset    ; (None -> var_4: address offset)

    calc_address_with_offset entity_container, var_4, address_1

    pla
    sta var_3

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

    sta (address_1), Y                      ; active components
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

    iny                                     ; get over active components
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Deactivates all components
;
; ARGS:
;  address_1            - entity address
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disable_all_entity_components: 
    lda #$00
    ldy #$03                                ; jump over position and mask
    sta (address_1), y
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Deactivates a certain component
;
; ARGS:
;  address_10            - entity address
;  temp_1                - component id
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
disable_one_entity_component: 
    lda #$ff
    sec
    sbc temp_1
    sta temp_2
    ldy #$03                                ; jump over position and mask
    lda (address_10), y
    and temp_2
    sta (address_10), y
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Deactivates a certain component
;
; ARGS:
;  address_10            - entity address
;  temp_1                - component id
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
enable_one_entity_component: 
    ldy #$03                                ; jump over position and mask
    lda (address_10), y
    ora temp_1
    sta (address_10), y
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update direction
;
; ARGS:
;  address_10            - entity address
;  temp_1                - dirX
;  temp_2                - dirY
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_movement_direction:
    ldy #$04
    lda (address_10), y                      ; fetch address of the movement component
    sta address_9
    iny

    lda (address_10), Y
    sta address_9 + 1

    ldy #$03                                ; offset to xDir
    lda temp_1
    sta (address_9), y

    iny                                     ; yDir
    lda temp_2
    sta (address_9), y 
    rts
