.include "constants.asm"
.include "globals.asm"
.include "macros.asm"
.include "structs.asm"

.export spawn_projectile
.export tick_projectiles

.import create_sprite
.import destroy_sprite
.import check_rect_intersection


OWNER_BIT = %00000001
KIND_BITS = %00000110


.rodata
;
; Bullet projectile animation.
;
bullet_anim:
    .byte $01   ; length frames
    .byte $00   ; speed
    .byte $13   ; starting tile ID
    .byte $01   ; attribute set
    .byte $01   ; padding x, z -> 2 tiles wide and high


;
; Projectile speeds table, in pixels per frame.
;
speeds_table:
    .byte 0    ; disabled
    .byte 1    ; bullet
    .byte 2    ; missile
    .byte 10   ; laser


.code
;
; Spawn a projectile.
;
; Parameters:
;   var1    - X coord
;   var2    - Y coord
;   var3    - attribute
;
; Returns:
;   ptr1    - projectile address
;
.proc spawn_projectile
            ;
            ; Create the sprite
            ;
            ; TODO: support other projectile types
            lda #<bullet_anim       ; point ptr1 to projectile animation (only bullet for now)
            sta ptr1
            lda #>bullet_anim
            sta ptr1 + 1
            jsr create_sprite       ; arguments (ptr1: sprite config, var1: x, var2: y) => ptr2: sprite component

            ;
            ; Initialize the projectile object
            ;
            lda #<projectiles       ; point ptr1 to projectiles array beinning
            sta ptr1
            lda #>projectiles
            sta ptr1 + 1
            ldy #Projectile::attr   ; load 'attr' field offset to y for indexing

            ; find the first free projectile object, use ptr1 as cursor
.mac find_none
            lda (ptr1),y            ; if 'attr' is 0, Z is set and iteration stops
.endmac
            find_ptr ptr1, projectiles_end, .sizeof(Projectile), find_none

            ; set the 'attr' field, conveniently, y still holds the offset to it
            lda var3
            sta (ptr1),y

            ; set the 'sprite' field, address of sprite component is in ptr2
            ldy #Projectile::sprite
            lda ptr2
            sta (ptr1),y
            iny
            lda ptr2 + 1
            sta (ptr1),y

            rts
.endproc


;
; Tick projectiles logic.
;
; Moves the projectiles, checks for collisions and destroys exhausted ones.
;
.proc tick_projectiles
            lda #<projectiles       ; point tmp5 to projectiles array beginning
            sta tmp5
            lda #>projectiles
            sta tmp5 + 1

.mac iter_proj
            ;
            ; Move projectiles based on their direction bit (up/down)
            ;
            ldy #Projectile::attr   ; offset to 'attr' field
            lda (tmp5),y            ; load attribute value
            sta tmp1                ; back it up to tmp1
            beq @end                ; skip if disabled component encountered
            and #KIND_BITS          ; AND with kind bit mask
            lsr                     ; extract the kind value, to be used as index in 'speed_table'
            tay                     ; move to y for using as index
            lda speeds_table,y      ; load the speed value for the given projectile kind
            sta tmp2                ; back it up to tmp2
            ldy #Projectile::sprite ; offset to 'sprite' field
            lda (tmp5),y            ; load lo part
            sta tmp7                ; save lo part to tmp7
            iny
            lda (tmp5),y            ; load hi part
            sta tmp7 + 1            ; save hi part to tmp7 + 1
            ldy #Sprite::pos + 1    ; index to Y coord in the sprite component
            lda (tmp7),y            ; load current Y coord value
            pha                     ; push to stack
            lda #OWNER_BIT          ; owner bit mask
            bit tmp1                ; check whether it's player or enemy
            beq @if_player
@if_enemy:  pla                     ; pull back the Y coord value
            clc
            adc tmp2                ; in case of enemy, add the speed to it (move down)
            bcs @destroy            ; on reaching the lower pixel row, destroy the projectile
            sta (tmp7),y            ; update Y
            jsr _collide_with_players
            bcs @destroy            ; destroy if carry is set (we have a collision)
            bcc @end                ; no hit, continue
@if_player: pla                     ; pull back the Y coord value
            sec
            sbc tmp2                ; in case of player, subtract the speed from it (move up)
            bcc @destroy            ; on reaching the topmost pixel row, destroy the projectile
            sta (tmp7),y            ; update Y
            jsr _collide_with_enemies
            bcc @end                ; carry clear if no collision, skip over, otherwise destroy the projectile
@destroy:   fill_mem tmp5, .sizeof(Projectile), #0  ; destroy the projectile
            fill_mem tmp7, .sizeof(Sprite), #0      ; destroy the sprite
@end:
.endmac
            ; execute the macro above for each projectile
            iter_ptr tmp5, projectiles_end, .sizeof(Projectile), iter_proj

            rts
.endproc


.proc _collide_with_enemies
.mac collide_enemy
            ldy #Enemy::sprite
            lda (tmp3),y            ; load sprite lo
            sta tmp9                ; save to tmp9
            iny
            lda (tmp3),y            ; load sprite hi
            beq @nohit              ; skip the check if the enemy sprite hi addr is null
            sta tmp10               ; save to tmp10 (tmp9 + 1)

            ldy #Sprite::pos
            lda (tmp9),y            ; load enemy X coord
            sta var1                ; var1 = enemy left side
            clc
            adc #16                 ; add the width
            sta var3                ; var3 = enemy right side
            iny
            lda (tmp9),y            ; load enemy Y coord
            sta var2                ; var2 = enemy top side
            clc
            adc #16                 ; add the height
            sta var4                ; var4 = enemy bottom side

            ldy #Sprite::pos
            lda (tmp7),y            ; load projectile X coord
            sta var5                ; var5 = projectile left side
            clc
            adc #8                  ; add projectile width
            sta var7                ; var7 = projectile right side
            iny
            lda (tmp7),y            ; load projectile Y coord
            sta var6                ; var6 = projectile top side
            clc
            adc #8                  ; add projectile height
            sta var8                ; var8 = projectile bottom side

            jsr check_rect_intersection
            bcc @nohit
            ldy #Enemy::hits
            lda (tmp3),y            ; load the number of hits
            clc
            adc #1                  ; increase by 1 (carry is set!)
            sta (tmp3),y            ; save it back
            sec                     ; set carry and return
            rts
@nohit:
.endmac

            ; (tmp3,tmp4) = pointer to current enemy (lo,hi)
            lda #<enemies
            sta tmp3
            lda #>enemies
            sta tmp4
            iter_ptr tmp3, enemies_end, .sizeof(Enemy), collide_enemy

            clc                     ; clear the carry, no collisions with enemies
            rts
.endproc


.proc _collide_with_players
.mac collide_player
            ldy #Player::ship
            lda (tmp3),y            ; load ship sprite lo
            sta tmp9                ; save to tmp9
            iny
            lda (tmp3),y            ; load ship sprite hi
            beq @nohit              ; skip the check if the player ship sprite hi addr is null
            sta tmp10               ; save to tmp10 (tmp9 + 1)

            ldy #Sprite::pos
            lda (tmp9),y            ; load player X coord
            sta var1                ; var1 = player left side
            clc
            adc #16                 ; add the width
            sta var3                ; var3 = player right side
            iny
            lda (tmp9),y            ; load player Y coord
            sta var2                ; var2 = player top side
            clc
            adc #16                 ; add the height
            sta var4                ; var4 = player bottom side

            ldy #Sprite::pos
            lda (tmp7),y            ; load projectile X coord
            sta var5                ; var5 = projectile left side
            clc
            adc #8                  ; add projectile width
            sta var7                ; var7 = projectile right side
            iny
            lda (tmp7),y            ; load projectile Y coord
            sta var6                ; var6 = projectile top side
            clc
            adc #8                  ; add projectile height
            sta var8                ; var8 = projectile bottom side

            jsr check_rect_intersection
            bcc @nohit
            ldy #Player::hits
            lda (tmp3),y            ; load the number of hits
            clc
            adc #1                  ; increase by 1 (carry is set!)
            sta (tmp3),y            ; save it back
            sec                     ; set carry and return
            rts
@nohit:
.endmac

            ; (tmp3,tmp4) = pointer to current player (lo,hi)
            lda #<players
            sta tmp3
            lda #>players
            sta tmp4
            iter_ptr tmp3, players_end, .sizeof(Player), collide_player

            clc                     ; clear the carry, no collisions with enemies
            rts
.endproc
