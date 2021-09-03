.export init_projectile_components
.export create_player_projectile
.export spawn_projectile
.export update_projectile_position

.include "constants.asm"
.include "globals.asm"
.include "macros.asm"

.import create_collision_component
.import create_sprite
.import create_movement_component
.import create_entity
.import disable_all_entity_components

;
; Projectile configuration
;
.rodata
projectile_default_anim:
    .byte $01                               ; length frames
    .byte $00                               ; speed
    .byte $13                               ; starting tile ID
    .byte $01                               ; attribute set
    .byte $01                               ; padding x, z -> 2 tiles wide and high


;bullet_properties_config:
;    .byte $10                               ; damage points


;PROJECTILE_SIZE = 12                         ; BYTES

MAX_PROJECTILES_IN_BUFFER = 1

.segment "BSS"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PROJECTILE:
;    .addr entity
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
projectile_component_container:     .res 20             ; 5 Projectiles (2x5)

num_current_projectiles:            .res 1
last_updated_projectile:            .res 1

.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc init_projectile_components
    lda #$00
    sta num_current_projectiles
    sta last_updated_projectile
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FILL PROJECTILE POOL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_player_projectile
    lda #$ff                                ; xPos
    sta var1
    lda #$32                                ; yPos
    sta var2
    lda #$00                                ; xDir
    sta var3
    lda #$02                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var4

    jsr spawn_projectile
    jsr disable_all_entity_components

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a projectile
; ARGS:
;   var1           - xPosition
;   var2           - yPosition
;   var3           - xDir
;   var4           - yDir, now one byte will be reduced
;
; RETURN:
;   ptr1       - projectile entity
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc spawn_projectile
    ; get offset in projectile buffer for new projectile

    lda num_current_projectiles
    cmp #MAX_PROJECTILES_IN_BUFFER
    bcc :+
    ; in case the projectile buffer is already full .. just take one projectile of this buffer and update it with the most recent
    ; data
    jsr update_projectile_position
    rts
:
    lda var4
    pha

    lda var3
    pha                                     ; push var3 (xDir) to stack

    lda #$00                          ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
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
    lda #<projectile_default_anim
    sta ptr2

    lda #>projectile_default_anim
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
    ora #ENEMY_LYR
    ora #PLAYER_LYR
    sta var1

    ; set collision layer
    lda #$00
    ora #PROJECTILE_LYR
    sta var2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (ptr2), y
    sta var3
    sta var4

    jsr create_collision_component             ; arguments (var1: mask, var2: layer, var3: w, var4:h ) => return ptr2 of component

    ; 7. Store collision component address in entity component buffer
    ldy #$08
    lda ptr2
    sta (ptr1), y
    iny

    lda ptr2 + 1
    sta (ptr1), y
    iny

    ; fill projectile buffer:
    ; store link to projectile entities in projectile buffer
    mult_with_constant num_current_projectiles, #2, var1
    calc_address_with_offset projectile_component_container, var1, ptr3

    ldy #$00                                ; owner lo
    lda ptr1
    sta (ptr3), y

    iny
    lda ptr1 + 1                        ; owner hi
    sta (ptr3), y
    iny

    inc num_current_projectiles

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
.proc update_projectile_position
    lda #<projectile_component_container
    sta ptr10

    lda #>projectile_component_container
    sta ptr10 + 1

    mult_with_constant last_updated_projectile, #2, var6

    ldy var6
    lda (ptr10), y
    sta ptr9

    iny
    lda (ptr10), Y
    sta ptr9 + 1

    ldy #$00
    lda var1                               ; store x and y pos
    sta (ptr9), Y
    iny

    lda var2
    sta (ptr9), Y

    ; update active component mask
    ldy #$03                                ; go over component mask
    lda (ptr9), Y
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    sta (ptr9), Y

    ; offset to movement_component
    lda var6
    clc
    adc #$04
    tay
    lda (ptr9), Y
    sta ptr8
    iny

    lda (ptr9), Y
    sta ptr8 + 1

    ldy #$03
    lda var3
    sta (ptr8), y                              ; xDir

    iny
    lda var4                                       ; yDir
    sta (ptr8), Y

    inc last_updated_projectile
    lda last_updated_projectile
    cmp #MAX_PROJECTILES_IN_BUFFER
    bcc :+
    lda #$00
    sta last_updated_projectile
 :  rts
.endproc
