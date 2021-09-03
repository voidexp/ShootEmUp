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
    sta var3
    lda #$00                                ; yDir
    sta var4

    lda #<squady_idle_animation
    sta ptr7

    lda #>squady_idle_animation
    sta ptr7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_spacetopus_enemy
    lda #$00                                ; xDir
    sta var3
    lda #$00                                ; yDir
    sta var4

    lda #<octi_idle_anim
    sta ptr7

    lda #>octi_idle_anim
    sta ptr7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_ufo_enemy
    lda #$00                                ; xDir
    sta var3
    lda #$00                                ; yDir
    sta var4

    lda #<ufo_idle_animation
    sta ptr7

    lda #>ufo_idle_animation
    sta ptr7 + 1

    jsr spawn_enemy

    rts
.endproc


.proc spawn_static_ufo_2_enemy
    lda #$00                                ; xDir
    sta var3
    lda #$00                                ; yDir
    sta var4

    lda #<ufo_2_idle_animation
    sta ptr7

    lda #>ufo_2_idle_animation
    sta ptr7 + 1

    jsr spawn_enemy

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a squad enemy
; ARGS:
;   var1           - xPos
;   var2           - yPos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc spawn_squady
    lda #$40                                ; xPos
    sta var1
    lda #$10                                ; yPos
    sta var2

    jsr spawn_static_squad_enemy

    lda #$c0                                ; xPos
    sta var1
    lda #$10                                ; yPos
    sta var2

    jsr spawn_static_squad_enemy

    lda #$40                                ; xPos
    sta var1
    lda #$50                                ; yPos
    sta var2

    jsr spawn_static_squad_enemy

    lda #$c0                                ; xPos
    sta var1
    lda #$50                                ; yPos
    sta var2

    jsr spawn_static_squad_enemy
    rts
.endproc


.proc spawn_spacetopus
    lda #$30                                ; xPos
    sta var1
    lda #$10                                ; yPos
    sta var2

    jsr spawn_static_ufo_2_enemy

    lda #$65                                ; xPos
    sta var1
    lda #$20                                ; yPos
    sta var2

    jsr spawn_static_spacetopus_enemy

    lda #$8e                                ; xPos
    sta var1
    lda #$20                                ; yPos
    sta var2

    jsr spawn_static_spacetopus_enemy

    lda #$c0                                ; xPos
    sta var1
    lda #$10                                ; yPos
    sta var2

    jsr spawn_static_ufo_enemy

    lda #$48                                ; xPos
    sta var1
    lda #$42                                ; yPos
    sta var2

    jsr spawn_static_ufo_enemy

    lda #$18                                ; xPos
    sta var1
    lda #$52                                ; yPos
    sta var2

    jsr spawn_static_spacetopus_enemy

    lda #$a8                                ; xPos
    sta var1
    lda #$42                                ; yPos
    sta var2

    jsr spawn_static_ufo_2_enemy

    lda #$d8                                ; xPos
    sta var1
    lda #$52                                ; yPos
    sta var2

    jsr spawn_static_spacetopus_enemy

    lda #$30                                ; xPos
    sta var1
    lda #$80                                ; yPos
    sta var2

    jsr spawn_static_ufo_2_enemy

    lda #$65                                ; xPos
    sta var1
    lda #$70                                ; yPos
    sta var2

    jsr spawn_static_spacetopus_enemy

    lda #$8e                                ; xPos
    sta var1
    lda #$70                                ; yPos
    sta var2
    ; rts
    jsr spawn_static_spacetopus_enemy

    lda #$c0                                ; xPos
    sta var1
    lda #$80                                ; yPos
    sta var2

    jsr spawn_static_ufo_enemy
    rts
.endproc


;
; Spawn an enemy of a given kind.
;
; Parameters:
;   var1       - kind of enemy to spawn, see 'EnemyKind' enum
;   var2       - X coord
;   var3       - Y coord
;
; Returns:
;   ptr1   - address of the enemy object
;
; Finds the first enemy object with NONE kind, initializes and returns its
; address.
;
.proc spawn_enemy_kind
            lda #<enemies       ; let 'ptr1' point to 'enemies' array
            sta ptr1
            lda #>enemies
            sta ptr1 + 1

.mac find_none                  ; macro executed on each 'Enemy' object
            lda (ptr1),y   ; if 'kind' is 0, Z is set and iteration stops
.endmac

            ldy #Enemy::kind    ; load 'kind' field offset to Y for indexing

            ; find the first free enemy object, 'ptr1' will point to it
            find_ptr ptr1, enemies_end, .sizeof(Enemy), find_none

            lda var3        ; enemy kind value
            sta (ptr1),y    ; save it to 'kind' field
            lda var1        ; X coord value
            ldy #Enemy::pos ; offset to X component of 'pos' field
            sta (ptr1),y    ; save X coord
            lda var2        ; Y coord value
            iny     ; offset to Y component of 'pos' field
            sta (ptr1),y        ; save Y coord

            lda ptr1        ; backup ptr1 on stack
            pha     ; lo part
            lda ptr2 + 1
            pha     ; hi part

            lda #<octi_idle_anim; point ptr1 to desired animation
            sta ptr1
            lda #>octi_idle_anim
            sta ptr1 + 1

            jsr create_sprite   ; create a sprite, result in ptr2

            pla                 ; enemy address hi
            sta ptr1 + 1   ; restore to ptr1 hi
            pla                 ; enemy address lo part
            sta ptr1       ; restore to ptr1 lo

            ldy #Enemy::sprite  ; offset to sprite field
            lda ptr2       ; sprite addr lo byte
            sta (ptr1),y   ; write to sprite field lo
            lda ptr2 + 1   ; sprite addr hi byte
            iny
            sta (ptr1),y   ; write to sprite field hi

            rts
.endproc


;
; Tick enemies.
;
; Iterates all enemy objects and performs collision detection, movement and
; rendering.
;
.proc tick_enemies
            lda #<enemies       ; let 'ptr1' point to 'enemies' array
            sta ptr1
            lda #>enemies
            sta ptr1 + 1

.mac tick_enemy
            ldy #Enemy::kind    ; load 'kind' field offset to Y for indexing
            lda (ptr1),y   ; if 'kind' is 0, Z is set and iteration stops

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
;   var1           - xPosition
;   var2           - yPosition
;   var3           - xDir
;   var4           - yDir, now one byte will be reduced
;   ptr7       - enemy sprite config
;
; RETURN:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc spawn_enemy
    lda var4
    pha

    lda var3
    pha                                     ; push var3 (xDir) to stack

    lda #$00                                ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    ora #ENEMY_CMP
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

    lda ptr7
    sta ptr2

    lda ptr7 + 1
    sta ptr2 + 1

    ; 4. Create SPRITE component
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
    ora #PLAYER_LYR
    sta var1

    ; set collision layer
    lda #$00
    ora #ENEMY_LYR
    sta var2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (ptr2), y
    sta var3
    sta var4

    jsr create_collision_component             ; arguments (var1: mask, var2: layer, var3: w, var4:h ) => return ptr2 of component

    ; 5. Store collision component address in entity component buffer
    ldy #$08
    lda ptr2
    sta (ptr1), y
    iny

    lda ptr2 + 1
    sta (ptr1), y


    ldy #$06
    lda (ptr1), y
    sta ptr2

    sta (ptr1), y
    sta ptr2 + 1

    jsr create_enemy_component             ; arguments (ptr1: owner, ptr2: sprite component) => return ptr3 of component

    ; 5. Store enemy component address in entity component buffer
    ldy #$0a
    lda ptr3
    sta (ptr1), y
    iny

    lda ptr3 + 1
    sta (ptr1), y
    iny

    rts
.endproc
