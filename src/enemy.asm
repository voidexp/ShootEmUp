;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ANIMATION SETTINGS
; length frames
; speed
; starting tile ID
; attribute set
; padding x, z -> 1 tiles wide and high
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
    .byte $03                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high


; TODO: add different settings for different states
squady:
    .addr squady_idle_animation             ; active animation
    ;.addr squady_idle_animation            ; destroying animation
    ;.addr squady_idle_animation            ; active sound
    ;.addr squady_idle_animation            ; destroying sound
    ; .byte $00                  

spacetopus:
    .addr octi_idle_anim


small_squad_army:
    .addr squady ;squady                    ; type of enemy
    .byte $40, $10                          ; x position, y position
    .addr squady
    .byte $c0, $10
    .addr spacetopus
    .byte $58, $32
    .addr spacetopus
    .byte $a8, $32
    .addr squady
    .byte $40, $50
    .addr squady
    .byte $c0, $50         

;
; Constants
;
NUM_ENEMIES = 6

ANIMATION_SPEED = 8

OFFSET_PADDING = 1
OFFSET_TILE_ID = 2
OFFSET_ATTRIBUTE_SET = 3       


.segment "RAM"
; 6 enemies, 5 bytes each
current_enemy_set:  .res 30 ; 2 byte enemy address, 2 byte position, 1 byte anim frame


;
; initialize enemy data
;
.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LOAD ENEMIES
; load small squad army from rom and store it in the enemy pool (current_enemy_set)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load_enemies:
    ; load config of small squad army into the animation set
    
    lda #NUM_ENEMIES
    sta var_1

    lda #<small_squad_army
    sta address_1

    lda #>small_squad_army
    sta address_1 + 1

    lda #<current_enemy_set
    sta address_2

    lda #>current_enemy_set
    sta address_2 + 1

    jsr load_animation_set
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE ENEMY ANIMATIONS
; update the animations 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_enemies:
    lda #NUM_ENEMIES
    sta var_1

    lda #<current_enemy_set                 ; low byte
    sta address_1

    lda #>current_enemy_set                 ; high byte
    sta address_1 + 1

    jsr update_animation_set                ; (var_1, address_1) tick enemy object animations
    rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DRAW ENEMY ANIMATIONS
; draw the tiles 
; ARGS:
; y                 - oam offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
draw_enemies:
    lda #NUM_ENEMIES
    sta var_1

    lda #<current_enemy_set                 ; low byte
    sta address_1

    lda #>current_enemy_set                 ; high byte
    sta address_1 + 1

    jsr draw_animation_set                  ; (y, var_1, address_1) draw enemy object animations
    rts