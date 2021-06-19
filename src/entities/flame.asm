.rodata
flame_default_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $03                               ; starting tile ID
    .byte $01                               ; attribute set
    .byte $01                               ; padding x, z -> 2 tiles wide and high

.segment "BSS"
num_flames: .res 1

.code

.proc init_flame_entities
    lda #$00
    sta num_flames
    rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; setup flame entity
; ARGS:
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;
; RETURN:
;   address_1       - address of flame entity
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_flame
    lda num_flames
    cmp #$01
    bcc :+
    rts
:

    lda #$00                                ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    sta var_3

    ; 1. Create Entity
    jsr create_entity                       ; None -> address_1 entity address

    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    ; 2. Create MOVEMENT component
    jsr create_movement_component           ; arguments (address_1: owner, var_1-4: config) => return address_2 of component

    ; 3. store address of movement component in entity component buffer
    ldy #$04
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y
    iny

    ; 4. Create SPRITE component
    lda #<flame_default_anim
    sta address_2

    lda #>flame_default_anim
    sta address_2 + 1

    jsr create_sprite_component             ; arguments (address_1: owner, address_2: sprite config) => return address_3 of component

    ; 5. Store sprite component address in entity component buffer
    ldy #$06
    lda address_3
    sta (address_1), y
    iny

    lda address_3 + 1
    sta (address_1), y
    iny

    inc num_flames
    rts
.endproc
