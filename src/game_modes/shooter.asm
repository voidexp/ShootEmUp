.include "structs.asm"
.include "globals.asm"
.include "macros.asm"

.import destroy_enemies
.import destroy_projectiles
.import game_over_mode
.import spawn_enemy
.import spawn_player
.import spawn_projectile
.import tick_enemies
.import tick_players
.import tick_projectiles

.rodata
;
; Descriptor of the shooter game mode.
;
shooter_mode:
    .addr shooter_init
    .addr shooter_fini
    .addr shooter_tick

.export shooter_mode


.code
;
; Initialization subroutine.
;
.proc shooter_init
            ;
            ; Spawn an enemy
            ;
            lda #130                ; X coord
            sta var1
            lda #100                ; Y coord
            sta var2
            lda #EnemyKind::UFO     ; enemy kind
            sta var3
            jsr spawn_enemy

            ;
            ; Spawn an enemy projectile
            ;
            lda #130
            sta var1
            lda #110
            sta var2
            lda #%011
            sta var3
            jsr spawn_projectile

            ;
            ; Spawn a player
            ;
            lda #130
            sta var1                ; X coord
            lda #210
            sta var2                ; Y coord
            jsr spawn_player

            rts
.endproc


;
; Cleanup subroutine.
;
.proc shooter_fini
            jsr destroy_enemies
            jsr destroy_projectiles
            rts
.endproc


;
; Game mode tick subroutine.
;
.proc shooter_tick
            jsr tick_projectiles
            jsr tick_enemies
            jsr tick_players

            ;
            ; Check the alive players counter and switch to game over mode if
            ; everyone is dead.
            ;
            lda players_alive       ; anybody alive?
            bne @end                ; if there is, bail out
            lda #<game_over_mode
            sta next_game_mode      ; set next game mode lo
            lda #>game_over_mode
            sta next_game_mode + 1  ; set next game mode hi

@end:       rts
.endproc
