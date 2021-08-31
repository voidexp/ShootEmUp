.include "globals.asm"

.import draw_end_text
.import draw_sprite_components
.import update_sprite_components
.import enemy_cmp_process_cd_results
.import update_collision_components
.import update_movement_components
.import update_actor_components
.import num_enemy_components
.import spawn_spacetopus
.import create_player
.import create_flame
.import create_player_projectile
.import initialize_entities
.import num_rainbows
.import update_anim_components
.importzp oam

.importzp update_animations, update_flags
.importzp kill_count, num_enemies_alive

.export battle_main_loop



ANIMATION_SPEED = 8


.code
.proc battle_main_loop
    ; jsr handle_input ; process input and reposition the ship
    ;
    ; update position of player
    ; check if one of the position bits is set if so, update the position of the player
update_player_position:
    ; check how often to increase the player position, depending on the speed
    lda update_flags
    cmp #$01  ; check if the last frame was drawn then update the position for the next one
    bcc update_anim_components

    jsr update_actor_components             ; process_controller_input

    ; UPDATE COMPONENTS
    jsr update_movement_components
    jsr update_collision_components

    jsr enemy_cmp_process_cd_results

update_anim_components:
    lda update_animations
    cmp #ANIMATION_SPEED
    bcc start_rendering
    jsr update_sprite_components
    lda #$00
    sta update_animations

    
start_rendering:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; START RENDERING SET OAM OFFSET TO 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldy #$00

draw_kill_count:

    lda num_enemies_alive
    cmp #$02
    bcc check_game_state
    lda #$0a        ; sprite xpos
    sta var_2
    lda kill_count
    sta var_1
    cmp #$0a

    bcc :+

    lda var_1
    sec
    sbc #$0a
    sta var_1

    ; move xpos for second tile
    lda var_2
    clc
    adc #$08
    sta var_2

    lda #$0c
    sta oam,Y
    iny
    ; sprite id
    lda #$31
    sta oam,Y
    iny
    ; sprite attrs
    lda #$01
    sta oam,Y
    iny
    ; X coord
    lda #$0a
    sta oam,Y
    iny

:   lda #$0c
    sta oam,Y
    iny
    ; sprite id
    lda #$30
    clc
    adc var_1
    sta oam,Y
    iny
    ; sprite attrs
    lda #$01
    sta oam,Y
    iny
    ; X coord
    lda var_2
    sta oam,Y
    iny

components:
    jsr draw_sprite_components
    jmp return_to_main
check_game_state:
    lda num_enemies_alive
    cmp #$02
    bcs return_to_main

    tya
    pha
    ; jsr create_rainbow
    pla
    tay
    jsr draw_end_text

return_to_main:
    rts
.endproc