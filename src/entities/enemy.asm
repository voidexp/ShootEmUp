.include "globals.asm"
.include "constants.asm"
.include "macros.asm"
.include "structs.asm"

.import create_enemy_component
.import create_collision_component
.import create_sprite
.import create_movement_component
.import create_entity

.export spawn_spacetopus
.export spawn_enemy_kind

.rodata
squady_idle_animation:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $20                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $01                               ; padding x, z -> 1 tiles wide and high

octi_idle_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $04                               ; starting tile ID
    .byte $02                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high

ufo_idle_animation:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $40                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $02                               ; padding x, z -> 1 tiles wide and high


ufo_2_idle_animation:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $48                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $02                               ; padding x, z -> 1 tiles wide and high

.code
.proc spawn_static_squad_enemy
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    lda #<squady_idle_animation
    sta address_7

    lda #>squady_idle_animation
    sta address_7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_spacetopus_enemy
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    lda #<octi_idle_anim
    sta address_7

    lda #>octi_idle_anim
    sta address_7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_ufo_enemy
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    lda #<ufo_idle_animation
    sta address_7

    lda #>ufo_idle_animation
    sta address_7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_ufo_2_enemy
    lda #$00                                ; xDir
    sta var_3
    lda #$00                                ; yDir
    sta var_4

    lda #<ufo_2_idle_animation
    sta address_7

    lda #>ufo_2_idle_animation
    sta address_7 + 1

    jsr spawn_enemy

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a squad enemy
; ARGS:
;   var_1           - xPos
;   var_2           - yPos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc spawn_squady
    lda #$40                                ; xPos
    sta var_1
    lda #$10                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    lda #$c0                                ; xPos
    sta var_1
    lda #$10                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    lda #$40                                ; xPos
    sta var_1
    lda #$50                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy

    lda #$c0                                ; xPos
    sta var_1
    lda #$50                                ; yPos
    sta var_2

    jsr spawn_static_squad_enemy
    rts
.endproc


.proc spawn_spacetopus
    lda #$30                                ; xPos
    sta var_1
    lda #$10                                ; yPos
    sta var_2

    jsr spawn_static_ufo_2_enemy

    lda #$65                                ; xPos
    sta var_1
    lda #$20                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$8e                                ; xPos
    sta var_1
    lda #$20                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$c0                                ; xPos
    sta var_1
    lda #$10                                ; yPos
    sta var_2

    jsr spawn_static_ufo_enemy

    lda #$48                                ; xPos
    sta var_1
    lda #$42                                ; yPos
    sta var_2

    jsr spawn_static_ufo_enemy

    lda #$18                                ; xPos
    sta var_1
    lda #$52                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$a8                                ; xPos
    sta var_1
    lda #$42                                ; yPos
    sta var_2

    jsr spawn_static_ufo_2_enemy

    lda #$d8                                ; xPos
    sta var_1
    lda #$52                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$30                                ; xPos
    sta var_1
    lda #$80                                ; yPos
    sta var_2

    jsr spawn_static_ufo_2_enemy

    lda #$65                                ; xPos
    sta var_1
    lda #$70                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$8e                                ; xPos
    sta var_1
    lda #$70                                ; yPos
    sta var_2
    ; rts
    jsr spawn_static_spacetopus_enemy

    lda #$c0                                ; xPos
    sta var_1
    lda #$80                                ; yPos
    sta var_2

    jsr spawn_static_ufo_enemy
    rts
.endproc


;
; Spawn an enemy of a given kind.
;
; Parameters:
;   var_1       - kind of enemy to spawn, see 'EnemyKind' enum
;   var_2       - X coord
;   var_3       - Y coord
;
; Returns:
;   address_1   - address of the enemy object
;
; Finds the first enemy object with NONE kind, initializes and returns its
; address.
;
.proc spawn_enemy_kind
            lda #<enemies       ; let 'address_1' point to 'enemies' array
            sta address_1
            lda #>enemies
            sta address_1 + 1

.mac find_none                  ; macro executed on each 'Enemy' object
            lda (address_1),y   ; if 'kind' is 0, Z is set and iteration stops
.endmac

            ldy #Enemy::kind    ; load 'kind' field offset to Y for indexing

            ; find the first free enemy object, 'address_1' will point to it
            find_ptr address_1, enemies_end, .sizeof(Enemy), find_none

            lda var_3           ; enemy kind value
            sta (address_1),y   ; save it to 'kind' field
            lda var_1           ; X coord value
            ldy #Enemy::pos     ; offset to X component of 'pos' field
            sta (address_1),y   ; save X coord
            lda var_2           ; Y coord value
            iny                 ; offset to Y component of 'pos' field
            sta (address_1),y   ; save Y coord

            lda address_1       ; backup address_1 on stack
            pha                 ; lo part
            lda address_2 + 1
            pha                 ; hi part

            lda #<octi_idle_anim; point address_1 to desired animation
            sta address_1
            lda #>octi_idle_anim
            sta address_1 + 1

            jsr create_sprite   ; create a sprite, result in address_2

            pla                 ; enemy address hi
            sta address_1 + 1   ; restore to address_1 hi
            pla                 ; enemy address lo part
            sta address_1       ; restore to address_1 lo

            ldy #Enemy::sprite  ; offset to sprite field
            lda address_2       ; sprite addr lo byte
            sta (address_1),y   ; write to sprite field lo
            lda address_2 + 1   ; sprite addr hi byte
            iny
            sta (address_1),y   ; write to sprite field hi

            rts
.endproc


;
; Tick enemies.
;
; Iterates all enemy objects and performs collision detection, movement and
; rendering.
;
.proc tick_enemies
            lda #<enemies       ; let 'address_1' point to 'enemies' array
            sta address_1
            lda #>enemies
            sta address_1 + 1

.mac tick_enemy
            ldy #Enemy::kind    ; load 'kind' field offset to Y for indexing
            lda (address_1),y   ; if 'kind' is 0, Z is set and iteration stops

            ; TODO: skip if 'kind' is NONE
            ; TODO: check for collision detection
            ; TODO: move
            ; TODO: draw
.endmac

            rts
.endproc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn an enemy
; ARGS:
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;   address_7       - enemy sprite config
;
; RETURN:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc spawn_enemy
    lda var_4
    pha

    lda var_3
    pha                                     ; push var_3 (xDir) to stack

    lda #$00                                ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    ora #ENEMY_CMP
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

    lda address_7
    sta address_2

    lda address_7 + 1
    sta address_2 + 1

    ; 4. Create SPRITE component
    jsr create_sprite             ; arguments (address_1: owner, address_2: sprite config) => return address_3 of component

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
    ora #PLAYER_LYR
    sta var_1

    ; set collision layer
    lda #$00
    ora #ENEMY_LYR
    sta var_2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (address_2), y
    sta var_3
    sta var_4

    jsr create_collision_component             ; arguments (var_1: mask, var_2: layer, var_3: w, var_4:h ) => return address_2 of component

    ; 5. Store collision component address in entity component buffer
    ldy #$08
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y


    ldy #$06
    lda (address_1), y
    sta address_2

    sta (address_1), y
    sta address_2 + 1

    jsr create_enemy_component             ; arguments (address_1: owner, address_2: sprite component) => return address_3 of component

    ; 5. Store enemy component address in entity component buffer
    ldy #$0a
    lda address_3
    sta (address_1), y
    iny

    lda address_3 + 1
    sta (address_1), y
    iny

    rts
.endproc
