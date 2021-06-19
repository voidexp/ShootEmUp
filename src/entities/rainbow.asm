.export create_rainbow
.export draw_end_text

.include "constants.asm"
.include "globals.asm"

.import create_entity
.import create_sprite_component

.rodata
rainbow_default_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $64                               ; starting tile ID
    .byte $02                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high

.segment "BSS"
num_rainbows: .res 1

.export num_rainbows

.code
.proc create_rainbow
    lda num_rainbows
    cmp #$01
    bcc :+
    rts
:
    lda #$79                                ; xPos
    sta var_1
    lda #$b4                                ; yPos
    sta var_2
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    lda #$00                          ; load component mask: sprite &&  movement component mask
    ora #SPRITE_CMP
    sta var_3

    ; 1. Create Entity
    jsr create_entity                       ; None -> address_1 entity address

    ; 4. Create SPRITE component
    lda #<rainbow_default_anim
    sta address_2

    lda #>rainbow_default_anim
    sta address_2 + 1

    jsr create_sprite_component             ; arguments (address_1: owner, address_2: sprite config) => return address_3 of component

    ; 5. Store sprite component address in entity component buffer
    ldy #$04
    lda address_3
    sta (address_1), y
    iny

    lda address_3 + 1
    sta (address_1), y
    iny

    inc num_rainbows
    rts
.endproc


.proc draw_end_text
    ; T
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$94
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord

    lda #$67
    sta oam,Y
    iny

    ; H
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$88
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord
    lda #$6f
    sta oam,Y
    iny


    ; E
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$85
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord
    lda #$77
    sta oam,Y
    iny

    ; E
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$85
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord

    lda #$87
    sta oam,Y
    iny

    ; N
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$8E
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord

    lda #$8f
    sta oam,Y
    iny

    ; D
    lda #$d0
    sta oam,Y
    iny
    ; sprite id
    lda #$84
    sta oam,Y
    iny
    ; sprite attrs
    lda #$03
    sta oam,Y
    iny
    ; X coord
    lda #$97
    sta oam,Y
    iny

    rts
.endproc
