.include "constants.asm"
.include "globals.asm"
.include "nes.asm"
.include "structs.asm"
.include "macros.asm"

.import create_sprite
.import spawn_projectile

.export spawn_player
.export tick_players


FLAME_XOFFSET = 4
FLAME_YOFFSET = 14
SHIP_WIDTH = 16
SHOOT_COOLDOWN = 60
PROJECTILE_XOFFSET = 4
PROJECTILE_YOFFSET = 255 - 4 ; -4 using two's complement

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
            ldy #Player::ship + 1   ; hi byte of the player ship, is null if the player is disabled
            lda (tmp1),y
            beq @skip               ; skip the player if there's no ship sprite

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

            jsr _handle_movement
            jsr _handle_shooting

@skip:      inx
.endmac
            lda #<players
            sta tmp1
            lda #>players
            sta tmp2
            ldx #0
            iter_ptr tmp1, players_end, .sizeof(Player), iter_player
.endproc


;
; Handle player movement based on the state of the related joypad buttons.
;
; (tmp1,tmp2)   - pointer to player
; (tmp3,tmp4)   - ship sprite
; (tmp6,tmp7)   - flame sprite
; x             - player index
;
.proc _handle_movement
@left:      lda pad1,x              ; load player's buttons state
            and #BUTTON_LEFT        ; should we move left?
            beq @right
            lda tmp5                ; load x coord
            beq @update_x           ; if x is zero, we reached left border, do not update
            dec tmp5                ; move left if there's room
            bvc @update_x           ; "unconditional" jump
@right:     lda pad1,x              ; load player's buttons state
            and #BUTTON_RIGHT       ; should we move right?
            beq @update_x
            lda tmp5                ; load x coord
            cmp #255 - SHIP_WIDTH   ; check against right screen border minus ship width
            beq @update_x           ; no update if right border is reached
            inc tmp5                ; move right if there's room
@update_x:  ldy #Sprite::pos
            lda tmp5
            sta (tmp3),y            ; update ship sprite x pos
            clc
            adc #FLAME_XOFFSET      ; add the flame offset
            sta (tmp6),y            ; update flame sprite pos
            rts
.endproc


;
; Handle shooting.
;
; (tmp1,tmp2)   - pointer to player
; (tmp3,tmp4)   - ship sprite
; (tmp6,tmp7)   - flame sprite
; x             - player index
;
.proc _handle_shooting
            ldy #Player::cooldown
            lda (tmp1),y            ; load cooldown value
            beq @shoot              ; cooldown elapsed, we can shoot
            clc
            sbc #1                  ; subtract a tick
            sta (tmp1),y            ; update the cooldown
            rts                     ; early return
@shoot:     lda pad1,x              ; load buttons for given player
            and #BUTTON_A           ; fire button pressed?
            beq @end
            lda #SHOOT_COOLDOWN
            sta (tmp1),y            ; reset cooldown, y still has the right offset
            lda tmp5                ; load x coord
            clc
            adc #PROJECTILE_XOFFSET ; add x offset
            sta var1                ; var1 = projectile x coord
            ldy #Sprite::pos + 1
            lda (tmp3),y            ; load y coord
            clc
            adc #PROJECTILE_YOFFSET ; add y offset
            sta var2                ; var2 = projectile y coord
            lda #%010               ; projectile attribute: player owned, bullet kind
            sta var3                ; var3 = projectile attribute

            ; save temporaries
            lda tmp1
            pha
            lda tmp2
            pha
            lda tmp3
            pha
            lda tmp4
            pha
            lda tmp5
            pha
            lda tmp6
            pha
            lda tmp7
            pha
            txa
            pha

            jsr spawn_projectile    ; spawn the projectile

            ; restore temporaries
            pla
            tax
            pla
            sta tmp7
            pla
            sta tmp6
            pla
            sta tmp5
            pla
            sta tmp4
            pla
            sta tmp3
            pla
            sta tmp2
            pla
            sta tmp1
@end:       rts
.endproc
