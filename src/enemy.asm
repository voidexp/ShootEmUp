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

ANIMATION_SPEED = 4

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
    lda small_squad_army, Y            ; x
	sta current_enemy_set, X 
    inx
    iny 
    lda small_squad_army, Y            ; y
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

    ; store the offset in the oam from to x
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
    lda (enemy_addr), Y           ; Get lobyte
	sta enemy_anim_addr + 1

    ; get y from stack
    pla 
    tay

    ; get the x position of the enemy, push it to stack
    ; sprite attrs
    lda current_enemy_set, y
    pha
    iny

    ; get the y position of enemy
    lda current_enemy_set, y
    sta oam, x
    inx
    iny

    ; get the current animation frame (tile id)
    lda current_enemy_set, y
    sta temp_1

    ; put current y on stack as we need it to accessing the sprite data
    tya 
    pha 


    ldy #$00
    ; get sprite id from the animation setting
    lda (enemy_anim_addr), y
    adc temp_1
    sta oam, X
    inx
    iny


    lda update_animations  ; check if the last frame was drawn then update the position for the next one
    cmp #ANIMATION_SPEED
    bmi :+

    inc temp_1                     ; increase current frame in animation
    ; get length of animation and check if the animation should restart
 :  lda (enemy_anim_addr), y
    cmp temp_1
    bne :+                         ; last frame of animation reached -> reset animation
    lda #$00
    sta temp_1
:

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
    pla             ; get enemy x pos from stack
    sta oam, x
    inx


    inc temp_2      ; check if all enemies are drawn, if yes, return to main
    lda temp_2
    cmp #NUM_ENEMIES
    bmi @draw_enemy

    ; set oam offset again to y
    
    lda update_animations
    cmp #ANIMATION_SPEED
    bmi :+
    lda #$00
    sta update_animations
 
 :  txa
    tay
    rts





