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

    ; ; 5. Store sprite component address in entity component buffer
    ;         ldy #$06
    ;         lda ptr3
    ;         sta (ptr1), y
    ;         iny

    ;         lda ptr3 + 1
    ;         sta (ptr1), y
    ;         iny

    ; ; 6. Create COLLISON component
    ; ; set collision mask
    ;         lda #$00
    ;         ora #ENEMY_LYR
    ;         ora #PLAYER_LYR
    ;         sta var1

    ; ; set collision layer
    ;         lda #$00
    ;         ora #PROJECTILE_LYR
    ;         sta var2

    ; ; get width and height from animation for the AABB
    ;         ldy #$04
    ;         lda (ptr2), y
    ;         sta var3
    ;         sta var4

    ;         jsr create_collision_component; arguments (var1: mask, var2: layer, var3: w, var4:h ) => return ptr2 of component

    ; ; 7. Store collision component address in entity component buffer
    ;         ldy #$08
    ;         lda ptr2
    ;         sta (ptr1), y
    ;         iny

    ;         lda ptr2 + 1
    ;         sta (ptr1), y
    ;         iny

    ; ; fill projectile buffer:
    ; ; store link to projectile entities in projectile buffer
    ; mult_with_constant num_current_projectiles, #2, var1
    ; calc_address_with_offset projectile_component_container, var1, ptr3

    ;         ldy #$00                ; owner lo
    ;         lda ptr1
    ;         sta (ptr3), y

    ;         iny
    ;         lda ptr1 + 1            ; owner hi
    ;         sta (ptr3), y
    ;         iny

    ;         inc num_current_projectiles

            rts
.endproc


;
; Tick projectiles logic.
;
; Moves the projectiles, checks for collisions and collects exhausted ones.
;
.proc tick_projectiles
            lda ptr1
            pha
            lda ptr1 + 1
            pha
            lda ptr2
            pha
            lda ptr2 + 1
            pha

.mac iter_proj
            ;
            ; Move projectiles based on their direction bit (up/down)
            ;
            ldy #Projectile::attr   ; offset to 'attr' field
            lda (ptr2),y            ; load attribute value
            sta tmp1                ; back it up to tmp1
            beq @end                ; skip if disabled component encountered
            and #KIND_BITS          ; AND with kind bit mask
            lsr                     ; extract the kind value, to be used as index in 'speed_table'
            tay                     ; move to y for using as index
            lda speeds_table,y      ; load the speed value for the given projectile kind
            sta tmp2                ; back it up to tmp2
            ldy #Projectile::sprite ; offset to 'sprite' field
            lda (ptr2),y            ; load lo part
            sta ptr1                ; save lo part to ptr1
            iny
            lda (ptr2),y            ; load hi part
            sta ptr1 + 1            ; save hi part to ptr1 + 1
            ldy #Sprite::pos + 1    ; index to Y coord in the sprite component
            lda (ptr1),y            ; load current Y coord value
            pha                     ; push to stack
            lda #OWNER_BIT          ; owner bit mask
            bit tmp1                ; check whether it's player or enemy
            beq @if_player
@if_enemy:  pla                     ; pull back the Y coord value
            clc
            adc tmp2                ; in case of enemy, add the speed to it (move down)
            bcs @destroy            ; on reaching the lower pixel row, destroy the projectile
            sta (ptr1),y            ; update Y
            jmp @end
@if_player: pla                     ; pull back the Y coord value
            sec
            sbc tmp2                ; in case of player, subtract the speed from it (move up)
            bcc @destroy            ; on reaching the topmost pixel row, destroy the projectile
            sta (ptr1),y            ; update Y
            jsr collide_with_enemies
            bcc @end                ; if no collision, skip over, otherwise destroy the projectile
@destroy:   fill_mem ptr2, .sizeof(Projectile), #0  ; destroy the projectile
            fill_mem ptr1, .sizeof(Sprite), #0      ; destroy the sprite
@end:
.endmac

            lda #<projectiles       ; point ptr2 to projectiles array beginning
            sta ptr2
            lda #>projectiles
            sta ptr2 + 1

            ; execute the macro above for each projectile
            iter_ptr ptr2, projectiles_end, .sizeof(Projectile), iter_proj

            pla
            sta ptr2 + 1
            pla
            sta ptr2
            pla
            sta ptr1 + 1
            pla
            sta ptr1

            rts
.endproc



.proc collide_with_enemies

.mac collide_enemy
            ldy #Enemy::pos
            lda (tmp3),y            ; load enemy X coord
            sta var1                ; var1 = enemy left side
            clc
            adc #16                 ; add the width
            sta var3                ; var3 = enemy right side
            iny
            lda (tmp3),y            ; load enemy Y coord
            sta var2                ; var2 = enemy top side
            clc
            adc #16                 ; add the height
            sta var4                ; var4 = enemy bottom side

            ldy #Sprite::pos
            lda (ptr1),y            ; load projectile X coord
            sta var5                ; var5 = projectile left side
            clc
            adc #8                  ; add projectile width
            sta var7                ; var7 = projectile right side
            iny
            lda (ptr1),y            ; load projectile Y coord
            sta var6                ; var6 = projectile top side
            clc
            adc #8                  ; add projectile height
            sta var8                ; var8 = projectile bottom side

            jsr check_rect_intersection
            bcc @nohit
            ldy #Enemy::hits
            lda (tmp3),y            ; load the number of hits
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

            clc
            rts
.endproc
