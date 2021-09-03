.include "globals.asm"
.include "constants.asm"

.import create_sprite
.import create_movement_component
.import create_entity

.export init_flame_entities
.export create_flame


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
;   var1           - xPosition
;   var2           - yPosition
;   var3           - xDir
;   var4           - yDir, now one byte will be reduced
;
; RETURN:
;   ptr1       - address of flame entity
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
    sta var3

    ; 1. Create Entity
    jsr create_entity                       ; None -> ptr1 entity address

    lda #$00                                ; xDir
    sta var3
    lda #$00                                ; yDir
    sta var4

    ; 2. Create MOVEMENT component
    jsr create_movement_component           ; arguments (ptr1: owner, var1-4: config) => return ptr2 of component

    ; 3. store address of movement component in entity component buffer
    ldy #$04
    lda ptr2
    sta (ptr1), y
    iny

    lda ptr2 + 1
    sta (ptr1), y
    iny

    ; 4. Create SPRITE component
    lda #<flame_default_anim
    sta ptr2

    lda #>flame_default_anim
    sta ptr2 + 1

    jsr create_sprite             ; arguments (ptr1: owner, ptr2: sprite config) => return ptr3 of component

    ; 5. Store sprite component address in entity component buffer
    ldy #$06
    lda ptr3
    sta (ptr1), y
    iny

    lda ptr3 + 1
    sta (ptr1), y
    iny

    inc num_flames
    rts
.endproc
