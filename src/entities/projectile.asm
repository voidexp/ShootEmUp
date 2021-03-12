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


projectile_anim_config:
    .byte HEALTH_STATE_ALIVE
    .addr projectile_default_anim


;bullet_properties_config:
;    .byte $10                               ; damage points


;PROJECTILE_SIZE = 12                         ; BYTES

MAX_PROJECTILES_IN_BUFFER = 1

.segment "RAM"
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
init_projectile_components:
    lda #$00
    sta num_current_projectiles
    sta last_updated_projectile
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FILL PROJECTILE POOL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
create_player_projectile:
    lda #$ff                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2
    lda #$00                                ; xDir
    sta var_3
    lda #$02                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4


    jsr spawn_projectile


    lda #$ff                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2
    lda #$00                                ; xDir
    sta var_3
    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4

    jsr spawn_projectile
    
    lda #$ff                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2
    lda #$00                                ; xDir
    sta var_3
    lda #$01                                ; yDir
    clc
    eor #$ff
    adc #$01
    sta var_4

    jsr spawn_projectile

    rts 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a projectile
; ARGS:
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;
; RETURN:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spawn_projectile:
    ; get offset in projectile buffer for new projectile

    lda num_current_entities
    cmp #MAX_PROJECTILES_IN_BUFFER
    bcc :+
    ; in case the projectile buffer is already full .. just take one projectile of this buffer and update it with the most recent
    ; data
    jsr update_projectile_position
    rts
:
    lda var_4
    pha

    lda var_3
    pha                                     ; push var_3 (xDir) to stack

    lda #$00                          ; load component mask: sprite &&  movement component mask
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
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
    lda #<projectile_default_anim
    sta address_2

    lda #>projectile_default_anim
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
    ora #ENEMY_LYR
    ora #PLAYER_LYR
    sta var_1

    ; set collision layer
    lda #$00
    ora #PROJECTILE_LYR
    sta var_2

    ; get width and height from animation for the AABB
    ldy #$04
    lda (address_2), y
    sta var_3
    sta var_4

    jsr create_collision_component             ; arguments (var_1: mask, var_2: layer, var_3: w, var_4:h ) => return address_2 of component
    
    ; 7. Store collision component address in entity component buffer
    ldy #$08
    lda address_2
    sta (address_1), y
    iny

    lda address_2 + 1
    sta (address_1), y
    iny

    ; fill projectile buffer:
    ; store link to projectile entities in projectile buffer
    mult_with_constant num_current_projectiles, #2, var_1
    calc_address_with_offset projectile_component_container, var_1, address_3 

    ldy #$00                                ; owner lo
    lda address_1
    sta (address_3), y

    iny
    lda address_1 + 1                        ; owner hi
    sta (address_3), y
    iny

    inc num_current_projectiles

    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update an existing projectile with a new position information
; ARGS:
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;   var_5           - speed
;
; RETURN:
;   None
; TODO: also update movement dir
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_projectile_position:
    lda #<projectile_component_container
    sta address_1

    lda #>projectile_component_container
    sta address_1 + 1

    mult_with_constant last_updated_projectile, #2, var_6


    ldy var_6
    lda (address_1), y
    sta address_2

    iny
    lda (address_1), Y
    sta address_2 + 1

    ldy #$00
    lda var_1
    sta (address_2), Y
    iny

    lda var_2
    sta (address_2), Y
    iny 
    iny                                     ; go over component mask
    lda (address_2), Y
    ora #MOVEMENT_CMP
    ora #SPRITE_CMP
    ora #COLLISION_CMP
    sta (address_2), Y

    ; offset to movement_component
    ldy #$04
    lda (address_2), Y
    sta address_3
    iny

    lda (address_2), Y
    sta address_3 + 1

    ldy #$03
    lda var_3                               ; xDir
    sta (address_3), Y

    iny
    lda var_4                                ; yDir
    sta (address_3), Y

    inc last_updated_projectile
    lda last_updated_projectile
    cmp #MAX_PROJECTILES_IN_BUFFER
    bcc :+
    lda #$00
    sta last_updated_projectile
 :  rts

create_projectile_component:
    ;mult_with_constant num_current_projectiles, #PROJECTILE_SIZE, var_5 
    ;inc var_5                               ; increase var_3 to have new address
    ;calc_address_with_offset projectile_container var_5 address_1

    rts
   

update_projectile_component:
    rts


    
