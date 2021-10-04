.include "constants.asm"
.include "globals.asm"
.include "nes.asm"
.include "structs.asm"

.import create_sprite

.export spawn_player

.rodata
ship_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $01                               ; starting tile ID
    .byte $00                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high


;
; Spawn a player.
;
; Parameters:
;   var1    - X coord
;   var2    - Y coord
;
; Returns:
;   ptr1    - player entity address
;
.proc spawn_player

            lda #<ship_anim         ; set ptr1 to ship_anim
            sta ptr1
            lda #>ship_anim
            sta ptr1 + 1
            jsr create_sprite       ; create the ship sprite, result in ptr2

            lda #<players
            sta ptr1
            lda #>players
            sta ptr1 + 1

            ldy #Player::ship
            lda ptr2
            sta (ptr1),y            ; save ship sprite lo
            iny
            lda ptr2 + 1
            sta (ptr1),y            ; save ship sprite hi

            rts
.endproc
