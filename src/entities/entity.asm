.include "macros.asm"
.include "globals.asm"

.import init_flame_entities
.import init_collision_components
; .import init_projectile_components
; .import init_sprites
.import init_movement_components

.export create_entity
.export disable_all_entity_components
.export update_movement_direction
.export enable_one_entity_component
.export disable_one_entity_component

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creates the entity by calculating the storage address of the entity, setting
; the position, mask
;
; ARGS:
;  var1                - posX
;  var2                - posY
;  var3                - component mask
;
; RETURN:
;   ptr1           - address of the entity config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_entity
    lda var3
    pha

    jsr get_current_entity_buffer_offset    ; (None -> var4: address offset)

    calc_address_with_offset entity_container, var4, ptr1

    pla
    sta var3

    ldy #$00
    lda var1
    sta (ptr1), Y
    iny

    lda var2
    sta (ptr1), Y
    iny

    lda var3
    sta (ptr1), y
    iny

    sta (ptr1), Y                      ; active components
    iny

    inc num_current_entities

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; returns entity offset for a given entity idop
; ARGS:
;  None
;
; RETURN:
;   var4           - address of the entity config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc get_current_entity_buffer_offset
; get entity component mask and calculate the number of components
; number of components => number of address bytes

    ldx num_current_entities
    ; first 2 bytes of the entity are the position, offset 2 for mask

    lda #<entity_container
    sta ptr1

    lda #>entity_container
    sta ptr1 + 1

    ldy #$00

    ;check if there are even entities there yet, otherwise return 0
    cpx #$00
    beq end
@entity_loop:
    iny
    iny                                     ; hop over position storage space
    lda (ptr1), Y                      ; get component mask
    sta var3

    iny                                     ; get over active components
    tya
    pha                                     ; push y on stack

    get_num_of_bits_set_in_mask var3, var4  ; get amount of components for this entity

    mult_with_constant var4, #2, var5     ; size of components buffer for this entity (2 bytes per component)

    pla                                     ; get y from stack

    clc
    adc var5                               ; add the offset of the component addresses
    tay

    dex
    cpx #$00
    bne @entity_loop
    iny                                     ;increase offset to new free byte
end:
    tya
    sta var4                               ; y -> current offset .. save it and go back
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Creates the entity by calculating the storage address of the entity, setting
; the position, mask
;
; ARGS:
;  var1                - posX
;  var2                - posY
;  var3                - component mask
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_entity_position
    lda #<entity_container
    sta ptr1

    lda #>entity_container
    sta ptr1 + 1

    ldy #$00
    lda var1
    sta (ptr1), Y
    iny

    lda var2
    sta (ptr1), Y
    iny

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Deactivates all components
;
; ARGS:
;  ptr1            - entity address
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc disable_all_entity_components
    lda #$00
    ldy #$03                                ; jump over position and mask
    sta (ptr1), y
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Deactivates a certain component
;
; ARGS:
;  ptr10            - entity address
;  tmp1                - component id
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc disable_one_entity_component
    lda #$ff
    sec
    sbc tmp1
    sta tmp2
    ldy #$03                                ; jump over position and mask
    lda (ptr10), y
    and tmp2
    sta (ptr10), y
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Activates a certain component
;
; ARGS:
;  ptr10            - entity address
;  tmp1                - component id
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc enable_one_entity_component
    ldy #$03                                ; jump over position and mask
    lda (ptr10), y
    ora tmp1
    sta (ptr10), y
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update direction
;
; ARGS:
;  ptr10            - entity address
;  tmp1                - dirX
;  tmp2                - dirY
;
; RETURN:
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_movement_direction
    ldy #$04
    lda (ptr10), y                      ; fetch address of the movement component
    sta ptr9
    iny

    lda (ptr10), Y
    sta ptr9 + 1

    ldy #$03                                ; offset to xDir
    lda tmp1
    sta (ptr9), y

    iny                                     ; yDir
    lda tmp2
    sta (ptr9), y
    rts
.endproc
