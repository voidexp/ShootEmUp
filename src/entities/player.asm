.include "constants.asm"
.include "globals.asm"
.include "nes.asm"

.import create_actor_component
.import create_collision_component
.import create_sprite_component
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
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;   address_4       - flame sprite config
;
; RETURN:
;   address_1       - address of player entity
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_player
    lda var_4
    pha

    lda var_3
    pha                                     ; push var_3 (xDir) to stack

    lda #$00                                ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    ora #ACTOR_CMP
    sta var_3

    ; 1. Create Entity
    jsr create_entity                       ; None -> address_1 entity address

    pla
    sta var_3                               ; get xDir from stack, store to var_3 again

    pla
    sta var_4

    ; 2. Create MOVEMENT component
    jsr create_movement_component           ; arguments (address_1: owner, var_1-4: config) => return address_2 of component

    ; 3. store address of movement component in entity component buffer
    ldy #$04
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y
    iny

    ; 4. Create SPRITE component
    lda #<player_ship_anim
    sta address_2

    lda #>player_ship_anim
    sta address_2 + 1

    jsr create_sprite_component             ; arguments (address_1: owner, address_2: sprite config) => return address_3 of component

    ; 5. Store sprite component address in entity component buffer
    ldy #$06
    lda address_3
    sta (address_1), y
    iny

    lda address_3 + 1
    sta (address_1), y
    iny

    ; 6. Create COLLISON component
    ; set collision mask
    lda #$00
    ora #PROJECTILE_LYR
    ora #ENEMY_LYR
    sta var_1

    ; set collision layer
    lda #$00
    ora #PLAYER_LYR
    sta var_2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (address_2), y
    sta var_3
    sta var_4

    jsr create_collision_component             ; arguments (var_1: mask, var_2: layer, var_3: w, var_4:h ) => return address_2 of component

    ; 5. Store collision component address in entity component buffer
    ldy #$0a
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y
    iny

    ; 6. Create actor component
    lda #PLAYER_ROLE
    sta var_1

    lda #<JOYPAD1              ; low byte
    sta address_3

    lda #>JOYPAD1              ; high byte
    sta address_3  + 1

    jsr create_actor_component              ; arguments (var_1: role, address_3: joystick, address_4: flame ) => return address_2 of component

    ldy #$0e
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y

    rts
.endproc
