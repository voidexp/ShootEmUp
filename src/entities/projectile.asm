.include "constants.asm"
.include "globals.asm"
.include "macros.asm"
.include "structs.asm"

.export spawn_projectile
.export tick_projectiles

.import create_sprite
.import destroy_sprite


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
            bcc @update_y
@if_player: pla                     ; pull back the Y coord value
            sec
            sbc tmp2                ; in case of player, subtract the speed from it (move up)
            bcc @destroy            ; on reaching the topmost pixel row, destroy the projectile
            bcs @update_y
@destroy:   fill_mem ptr2, .sizeof(Projectile), #0  ; destroy the projectile
            fill_mem ptr1, .sizeof(Sprite), #0      ; destroy the sprite
            bvc @end                ; cheaper then jmp
@update_y:  sta (ptr1),y            ; save the update Y coord back to the sprite component
@end:
.endmac

            lda #<projectiles       ; point ptr2 to projectiles array beginning
            sta ptr2
            lda #>projectiles
            sta ptr2 + 1

            ; execute the macro above for each projectile
            iter_ptr ptr2, projectiles_end, .sizeof(Projectile), iter_proj

            rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update an existing projectile with a new position information
; ARGS:
;   var1           - xPosition
;   var2           - yPosition
;   var3           - xDir
;   var4           - yDir, now one byte will be reduced
;   var5           - speed
;
; RETURN:
;   None
; TODO: also update movement dir
; MODIFIES:
;   ptr10, ptr9, ptr8
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; .proc update_projectile_position
;             lda #<projectile_component_container
;             sta ptr10

;             lda #>projectile_component_container
;             sta ptr10 + 1

;     mult_with_constant last_updated_projectile, #2, var6

;             ldy var6
;             lda (ptr10), y
;             sta ptr9

;             iny
;             lda (ptr10), Y
;             sta ptr9 + 1

;             ldy #$00
;             lda var1                ; store x and y pos
;             sta (ptr9), Y
;             iny

;             lda var2
;             sta (ptr9), Y

;     ; update active component mask
;             ldy #$03                ; go over component mask
;             lda (ptr9), Y
;             ora #MOVEMENT_CMP
;             ora #SPRITE_CMP
;             ora #COLLISION_CMP
;             sta (ptr9), Y

;     ; offset to movement_component
;             lda var6
;             clc
;             adc #$04
;             tay
;             lda (ptr9), Y
;             sta ptr8
;             iny

;             lda (ptr9), Y
;             sta ptr8 + 1

;             ldy #$03
;             lda var3
;             sta (ptr8), y           ; xDir

;             iny
;             lda var4                ; yDir
;             sta (ptr8), Y

;             inc last_updated_projectile
;             lda last_updated_projectile
;             cmp #MAX_PROJECTILES_IN_BUFFER
;             bcc :+
;             lda #$00
;             sta last_updated_projectile
; :           rts
; .endproc
