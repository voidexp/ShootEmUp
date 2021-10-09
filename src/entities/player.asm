.include "constants.asm"
.include "globals.asm"
.include "nes.asm"
.include "structs.asm"
.include "macros.asm"

.import create_sprite
.export spawn_player
.export tick_players


FLAME_XOFFSET = 4
FLAME_YOFFSET = 14
SHIP_WIDTH = 16

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


.proc tick_players
.mac iter_player
            pla                     ; pull the player index from stack
            tax                     ; move to x

            ;
            ; Check whether the player is enabled
            ;
            ldy #Player::ship + 1   ; hi byte of the player ship, is null if the player is disabled
            lda (tmp1),y
            beq @skip               ; skip the player if there's no ship sprite

            ;
            ; Handle movement
            ;
            jsr _handle_movement

            inx
            txa
            pha
@skip:
.endmac
            lda #<players
            sta tmp1
            lda #>players
            sta tmp2
            lda #0
            pha
            iter_ptr tmp1, players_end, .sizeof(Player), iter_player
.endproc


;
; Handle player movement based on the state of the related joypad buttons.
;
; (tmp1,tmp2)   - pointer to player
; x             - player index
;
.proc _handle_movement
            ldy #Player::ship
            lda (tmp1),y
            sta tmp3                ; tmp3 - ship sprite lo
            iny
            lda (tmp1),y
            sta tmp4                ; tmp4 - ship sprite hi

            ldy #Player::flame
            lda (tmp1),y
            sta tmp6                ; tmp6 - flame sprite lo
            iny
            lda (tmp1),y
            sta tmp7                ; tmp7 - flame sprite hi

            ldy #Sprite::pos
            lda (tmp3),y            ; load x coord
            sta tmp5                ; save to tmp5

@left:      lda pad1,x              ; load player's buttons state
            and #BUTTON_LEFT        ; should we move left?
            beq @right
            lda tmp5                ; load x coord
            beq @update_x           ; no update if left border is reached
            dec tmp5                ; move left if there's room
            bvc @update_x
@right:     lda pad1,x              ; load player's buttons state
            and #BUTTON_RIGHT       ; should we move right?
            beq @update_x
            lda tmp5                ; load x coord
            cmp #255 - SHIP_WIDTH   ; check against right screen border
            beq @update_x           ; no update if right border is reached
            inc tmp5                ; move right if there's room
@update_x:  ldy #Sprite::pos
            lda tmp5
            sta (tmp3),y            ; update ship sprite pos
            clc
            adc #FLAME_XOFFSET
            sta (tmp6),y            ; update flame sprite pos
            rts
.endproc
