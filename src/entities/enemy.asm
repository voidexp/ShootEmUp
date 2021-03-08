.rodata
squady_idle_animation:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $20                               ; starting tile ID
    .byte $02                               ; attribute set
    .byte $01                               ; padding x, z -> 1 tiles wide and high

octi_idle_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $04                               ; starting tile ID
    .byte $02                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high


.code
spawn_static_squad_enemy:
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

spawn_static_spacetopus_enemy:
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn a squad enemy
; ARGS:
;   var_1           - xPos
;   var_2           - yPos     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                          
spawn_squady:
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

spawn_spacetopus:
    lda #$58                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy

    lda #$a8                                ; xPos
    sta var_1
    lda #$32                                ; yPos
    sta var_2

    jsr spawn_static_spacetopus_enemy
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; spawn an enemy
; ARGS:
;   var_1           - xPosition
;   var_2           - yPosition
;   var_3           - xDir
;   var_4           - yDir, now one byte will be reduced
;   address_2       - enemy sprite config
;
; RETURN:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spawn_enemy:
    lda var_4
    pha

    lda var_3
    pha                                     ; push var_3 (xDir) to stack

    lda #%00000011                          ; load component mask: sprite &&  movement component mask
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
    ldy #$03
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
    jsr create_sprite_component             ; arguments (address_1: owner, address_2: sprite config) => return address_3 of component
    
    ; 5. Store sprite component address in entity component buffer
    ldy #$05
    lda address_3
    sta (address_1), y
    iny

    lda address_3 + 1
    sta (address_1), y
    ;iny

    rts
