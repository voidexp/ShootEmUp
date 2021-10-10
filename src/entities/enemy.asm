.include "globals.asm"
.include "constants.asm"
.include "macros.asm"
.include "structs.asm"

.import create_sprite
.import destroy_sprite

.export destroy_enemies
.export destroy_enemy
.export spawn_enemy
.export tick_enemies


.rodata
squady_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $20                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $01                               ; padding x, z -> 1 tiles wide and high

octi_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $04                               ; starting tile ID
    .byte $02                               ; attribute set
    .byte $02                               ; padding x, z -> 2 tiles wide and high

ufo_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $40                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $02                               ; padding x, z -> 1 tiles wide and high

ufo2_anim:
    .byte $04                               ; length frames
    .byte $08                               ; speed
    .byte $48                               ; starting tile ID
    .byte $03                               ; attribute set
    .byte $02                               ; padding x, z -> 1 tiles wide and high


.code
;
; Spawn an enemy of a given kind.
;
; Parameters:
;   var1       - X coord
;   var2       - Y coord
;   var3       - kind of enemy to spawn, see 'EnemyKind' enum
;
; Returns:
;   ptr1   - address of the enemy object
;
; Finds the first enemy object with NONE kind, initializes and returns its
; address.
;
.proc spawn_enemy
            lda #<octi_anim         ; point ptr1 to octi_anim
            sta ptr1
            lda #>octi_anim
            sta ptr1 + 1

            jsr create_sprite       ; create a sprite for the enemy, address is in ptr2

.mac find_none
            ldy #Enemy::kind
            lda (ptr1),y            ; load 'kind'; if 0, iteration stops
.endmac

            lda #<enemies           ; point ptr1 to enemies array
            sta ptr1
            lda #>enemies
            sta ptr1 + 1
            find_ptr ptr1, enemies_end, .sizeof(Enemy), find_none   ; find the first empty enemy record

            lda var3
            sta (ptr1),y            ; set 'kind' field; y already has the right index

            ldy #Enemy::sprite
            lda ptr2
            sta (ptr1),y            ; set 'sprite' field lo
            iny
            lda ptr2 + 1
            sta (ptr1),y            ; set 'sprite' field hi

            rts
.endproc


;
; Destroy a given enemy.
;
; Parameters:
;   ptr1    - address of a valid enemy object.
;
.proc destroy_enemy
            ldy #Enemy::sprite
            lda (ptr1),y
            sta ptr2                ; ptr2 lo = sprite lo
            iny
            lda (ptr1),y
            sta ptr2 + 1            ; ptr2 hi = sprite hi
            lda ptr1
            pha                     ; save ptr1 lo to stack
            lda ptr1 + 1
            pha                     ; save ptr1 hi to stack
            lda ptr2
            sta ptr1                ; ptr1 lo = sprite lo
            lda ptr2 + 1
            sta ptr1 + 1            ; ptr1 hi = sprite hi
            jsr destroy_sprite      ; destroy the sprite associated with the enemy
            pla
            sta ptr1 + 1            ; restore ptr1 hi
            pla
            sta ptr1                ; restore ptr1 lo
            fill_mem ptr1, .sizeof(Enemy), #0   ; clear the enemy record
            rts
.endproc


;
; Destroy all enemies.
;
.proc destroy_enemies
            lda ptr1
            pha                     ; save ptr1 lo
            lda ptr1 + 1
            pha                     ; save ptr1 hi

.mac iter_enemy
            ldy #Enemy::kind
            lda (ptr1),y            ; load enemy kind
            beq @skip               ; if 0 (disabled), skip this enemy
            jsr destroy_enemy
@skip:
.endmac
            lda #<enemies
            sta ptr1
            lda #>enemies
            sta ptr1 + 1
            iter_ptr ptr1, enemies_end, .sizeof(Enemy), iter_enemy

            pla
            sta ptr1 + 1            ; restore ptr1 hi
            pla
            sta ptr1                ; restore ptr1 lo

            rts
.endproc


;
; Tick enemies.
;
; Iterates all enemy objects and performs collision detection, movement and
; rendering.
;
.proc tick_enemies
            lda ptr1
            pha
            lda ptr1 + 1
            pha

.mac tick_enemy
            ldy #Enemy::kind
            lda (ptr1),y            ; load 'kind' attribute
            beq @end                ; skip this enemy if zero

            ldy #Enemy::hits
            lda (ptr1),y            ; load 'hits' attribute
            beq @end                ; skip if this enemy wasn't hit
            jsr destroy_enemy       ; destroy if there were hits
@end:
.endmac

            lda #<enemies
            sta ptr1
            lda #>enemies
            sta ptr1 + 1
            iter_ptr ptr1, enemies_end, .sizeof(Enemy), tick_enemy

            pla
            sta ptr1 + 1
            pla
            sta ptr1

            rts
.endproc
