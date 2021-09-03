.include "constants.asm"
.include "globals.asm"
.include "nes.asm"

.import create_actor_component
.import create_collision_component
.import create_sprite
.import create_movement_component
.import create_entity

.export create_player

.rodata

;
; Player ship is made up of 4 sprites in a 2x2 box, as below following:
; +--+--+
; |00|01|
; +--+--+
; |10|11|
; +--+--+
player_ship_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $01                               ; starting tile ID
    .byte $00                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; setup player entity
; ARGS:
;   var1           - xPosition
;   var2           - yPosition
;   var3           - xDir
;   var4           - yDir, now one byte will be reduced
;   ptr4       - flame sprite config
;
; RETURN:
;   ptr1       - address of player entity
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_player
    lda var4
    pha

    lda var3
    pha                                     ; push var3 (xDir) to stack

    lda #$00                                ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    ora #ACTOR_CMP
    sta var3

    ; 1. Create Entity
    jsr create_entity                       ; None -> ptr1 entity address

    pla
    sta var3                               ; get xDir from stack, store to var3 again

    pla
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
    lda #<player_ship_anim
    sta ptr2

    lda #>player_ship_anim
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

    ; 6. Create COLLISON component
    ; set collision mask
    lda #$00
    ora #PROJECTILE_LYR
    ora #ENEMY_LYR
    sta var1

    ; set collision layer
    lda #$00
    ora #PLAYER_LYR
    sta var2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (ptr2), y
    sta var3
    sta var4

    jsr create_collision_component             ; arguments (var1: mask, var2: layer, var3: w, var4:h ) => return ptr2 of component

    ; 5. Store collision component address in entity component buffer
    ldy #$0a
    lda ptr2
    sta (ptr1), y
    iny

    lda ptr2 + 1
    sta (ptr1), y
    iny

    ; 6. Create actor component
    lda #PLAYER_ROLE
    sta var1

    lda #<JOYPAD1              ; low byte
    sta ptr3

    lda #>JOYPAD1              ; high byte
    sta ptr3  + 1

    jsr create_actor_component              ; arguments (var1: role, ptr3: joystick, ptr4: flame ) => return ptr2 of component

    ldy #$0e
    lda ptr2
    sta (ptr1), y
    iny

    lda ptr2 + 1
    sta (ptr1), y

    rts
.endproc
