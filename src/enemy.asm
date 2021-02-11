;
; Animation settings
;
.code
enemy_idle_animation:
    .byte $20                   ; starting tile ID
    .byte $04                   ; length frames
    .byte $02                   ; attribute set


; TODO: add different settings for different states
squady:
    .addr enemy_idle_animation          ; HI Ivan!         ;  idle animation
    ; .byte $00                  



; todo: add padding
.code
small_squad_army:
    .addr squady                 ; type of enemy         PS: are you suffering already
    .byte $40, $10              ; x position, y position  PPS: now? :*
    .addr squady
    .byte $c0, $10
    .addr squady
    .byte $58, $32
    .addr squady
    .byte $a8, $32
    .addr squady
    .byte $40, $50
    .addr squady
    .byte $c0, $50                


.segment "RAM"
; 6 enemies, 5 bytes each
; TODO: add (health) state
current_enemy_set:  .res 30 ; 2 byte enemy address, 2 byte address, 1 byte anim state


NUM_ENEMIES = 6

ANIMATION_SPEED = 8

;
; initialize enemy data
;
.code
init_enemy_animation:
    lda #$00
    sta temp_1

    ldy #$00        ; loading offset
    ldx #$00        ; storing offset
@load_enemy:
    ; cpy to ram

    ; get the address of the animation setting
    lda small_squad_army, Y            ; Get lobyte
	sta current_enemy_set, X
    inx
    iny
    lda small_squad_army, Y            ; Get lobyte
	sta current_enemy_set, X 
    inx
    iny 
    ; store initial position
    lda small_squad_army, Y             ; x-position
	sta current_enemy_set, X 
    inx
    iny 
    lda small_squad_army, Y             ; y-position
	sta current_enemy_set, X 
    inx
    iny 
    ; set initial frame
    lda #$00
    sta current_enemy_set, X 
    inx

    ; check if there are more enemies to load
    inc temp_1
    lda temp_1
    cmp #NUM_ENEMIES
    bmi @load_enemy
    rts


init_enemies:
    ; load enemy set and store current set in RAM
    ; 

draw_enemies:
    ; iterate over enemies
    ; push y and x position to stack
    ; get correct anim
    ; draw 
    lda #$00
    ;sta temp_1
    sta temp_2                  ; amount of enemies processed
    sta temp_3                  ; anim frame to add
    
    lda update_animations
    cmp #ANIMATION_SPEED
    bmi :+
    inc temp_3
    lda #$00
    sta update_animations
    
:   ; store the offset in the oam from to x
    tya 
    tax 

    ldy #$00
@draw_enemy:
    ; get the address of the enemy setting
    lda current_enemy_set, y            ; Get lobyte
	sta enemy_addr
    iny
    lda current_enemy_set, y            ; Get lobyte
	sta enemy_addr + 1
    iny

    ; push y to stack
    tya
    pha

    ldy #$00
    ; get the address of the enemy animation
    lda (enemy_addr), Y
    sta enemy_anim_addr
    iny
    lda (enemy_addr), Y
	sta enemy_anim_addr + 1

    ; get y from stack
    pla
    tay

    ; get the x position of the enemy, push it to stack
    ; sprite attrs
    lda current_enemy_set, y
    pha
    iny

    ; get the y position of enemy and store it for the current sprite
    lda current_enemy_set, y
    sta oam, x
    inx
    iny

    ; get the current animation frame (tile id)
    lda current_enemy_set, y
    clc 
    adc temp_3
    sta temp_1

    ; put current y on stack as we need it to accessing the sprite data
    tya 
    pha
    ldy #$00
    ; get sprite id from the animation setting
    lda (enemy_anim_addr), y
    clc
    adc temp_1
    sta oam, X
    inx
    iny

    lda temp_3                      ; if an anim frame should be added check if it is the last one
    cmp #$01
    bne @after_reset
    ; get length of animation and check if the animation should restart
    lda (enemy_anim_addr), y
    cmp temp_1
    bne @after_reset                 ; last frame of animation reached -> reset animation
    lda #$00
    sta temp_1

@after_reset:
    iny
    ; get sprite attribute
    lda (enemy_anim_addr), Y
    sta oam, X
    inx

    ; take ebemy list offset from stack and store it in y
    pla 
    tay 

    ; store current animation frame
    lda temp_1
    sta current_enemy_set, y
    iny

    ; X coord
    ; get enemy x pos from stack
    pla
    sta oam, x
    inx


    inc temp_2      ; check if all enemies are drawn, if yes, return to main
    lda temp_2
    cmp #NUM_ENEMIES
    bmi @draw_enemy
 
 :  txa
    tay
    rts





