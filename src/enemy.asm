enemy:
    .byte $00                   ; animation address
    .byte $20                   ; y-position
    .byte $20                   ; x-position
    .byte $00                  


;
; Animation settings
;
.code
enemy_idle_animation:
    .byte $20                   ; starting tile ID
    .byte $04                   ; length frames
    .byte $02                   ; attribute set

; todo: add padding


NUM_ENEMIES = 6

;
; list of enemies
;
;.segment "RAM"
enemy_set:
    .addr enemy_idle_animation  ; address of animation setting
    .byte $40, $10              ; x position, y position
    .byte $00                   ; current animation frame
    .addr enemy_idle_animation
    .byte $c0, $10
    .byte $00
    .addr enemy_idle_animation
    .byte $58, $32
    .byte $00   
    .addr enemy_idle_animation
    .byte $a8, $32
    .byte $00
    .addr enemy_idle_animation
    .byte $40, $50
    .byte $00
    .addr enemy_idle_animation
    .byte $c0, $50                
    .byte $00

;
; initialize enemy data
;
.code
init_enemy_animation:
    lda #$00
    sta temp_1
    rts    

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
    ; get the address of the animation setting
    lda enemy_set, Y            ; Get lobyte
	sta enemy_anim_addr
    iny
    lda enemy_set, Y            ; Get lobyte
	sta enemy_anim_addr + 1
    iny

    ; get the x position of the enemy, push it to stack
    ; sprite attrs
    lda enemy_set, y
    pha
    iny

    ; get the y position of enemy
    lda enemy_set, y
    sta oam, x
    inx
    iny

    ; get the current animation tile id
    ;lda enemy_set, y
    ;sta temp_1

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

    inc temp_1                     ; increase current frame in animation
    ; get length of animation and check if the animation should restart
    lda (enemy_anim_addr), y
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
    sta enemy_set, y
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
    txa
    tay
    rts





