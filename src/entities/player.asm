.include "constants.asm"
.include "globals.asm"
.include "nes.asm"
.include "structs.asm"

.import create_sprite
.export spawn_player

FLAME_XOFFSET = 4
FLAME_YOFFSET = 14

.rodata
;
; Ship animation
;
ship_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $01                               ; starting tile ID
    .byte $00                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high

;
; Ship exhaust flame animation
;
flame_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $03                               ; starting tile ID
    .byte $01                               ; attribute set
    .byte $01                               ; padding x, z -> 2 tiles wide and high


.code
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
            ;
            ; Ship sprite creation
            ;
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

            ;
            ; Flame sprite creation
            ;
            lda var1
            clc
            adc #FLAME_XOFFSET      ; add horizontal offset to flame X coord
            sta var1                ; save back to var1
            lda var2
            clc
            adc #FLAME_YOFFSET      ; add vertical offset to flame Y coord
            sta var2                ; save back to var2
            lda #<flame_anim        ; set ptr1 to flame_anim
            sta ptr1
            lda #>flame_anim
            sta ptr1 + 1
            jsr create_sprite       ; create the flame sprite, result in ptr2

            lda #<players
            sta ptr1
            lda #>players
            sta ptr1 + 1

            ldy #Player::flame
            lda ptr2
            sta (ptr1),y            ; save flame sprite lo
            iny
            lda ptr2 + 1
            sta (ptr1),y            ; save flame sprite hi

            rts
.endproc
