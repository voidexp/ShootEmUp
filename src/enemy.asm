
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Enemy animation set
; start with a simple animation set
;
; tile ID
; attribute set
; length in frames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
enemy_idle_animation:
    .byte $20                   ; starting tile ID
    .byte $04                   ; length frames
    .byte $02                   ; attribute set


;
; initialize enemy data
;
init_enemy_animation:
    lda #$00
    sta current_animatiom_frame

    lda #$50
    sta enemy_pos_x
    lda #$50
    sta enemy_pos_y
    rts    

;
; play idle animation:
; todo: take animation address as parameter and load this anim
;
play_enemy_idle_animation:
	;ldy #$00
	;
    ; sprite $03
    ;
    ; Y coord
    lda enemy_pos_y
    sta oam,Y
    iny

    ldx #$00
    ; load current sprite id
    lda enemy_idle_animation, x
    clc
    adc current_animatiom_frame
    sta oam, Y
    iny
    
    ;check if animation reached end of frames and requires a reset
    inc current_animatiom_frame

    inx                                     ; increase x to get the length of the animation in frames
    lda #$04                                ; get number of frames from the animation
    cmp current_animatiom_frame
    bpl @continue_anim
    lda #$00
    sta current_animatiom_frame
@continue_anim:
    inx                                     ; increase to get the attributes
    ; sprite attrs
    lda enemy_idle_animation, x
    sta oam, Y
    iny

    ; X coord
    lda enemy_pos_x
    sta oam, Y
    iny
    rts