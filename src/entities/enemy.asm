.include "globals.asm"
.include "constants.asm"
.include "macros.asm"
.include "structs.asm"

.import create_sprite
.import destroy_sprite

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
;   var1       - kind of enemy to spawn, see 'EnemyKind' enum
;   var2       - X coord
;   var3       - Y coord
;
; Returns:
;   ptr1   - address of the enemy object
;
; Finds the first enemy object with NONE kind, initializes and returns its
; address.
;
.proc spawn_enemy

.mac find_none
            ldy #Enemy::kind
            lda (ptr1),y            ; load 'kind'; if 0, Z is set and iteration stops
.endmac

            lda #<enemies           ; let 'ptr1' point to 'enemies' array
            sta ptr1
            lda #>enemies
            sta ptr1 + 1
            find_ptr ptr1, enemies_end, .sizeof(Enemy), find_none

            lda var3                ; enemy kind value
            sta (ptr1),y            ; save it to 'kind' field
            lda var1                ; X coord value
            ldy #Enemy::pos         ; offset to X component of 'pos' field
            sta (ptr1),y            ; save X coord
            lda var2                ; Y coord value
            iny                     ; offset to Y component of 'pos' field
            sta (ptr1),y            ; save Y coord

            lda ptr1                ; backup ptr1 on stack
            pha                     ; lo part
            lda ptr1 + 1
            pha                     ; hi part

            lda #<octi_anim    ; point ptr1 to desired animation
            sta ptr1
            lda #>octi_anim
            sta ptr1 + 1

            jsr create_sprite       ; create a sprite, result in ptr2

            pla                     ; enemy address hi
            sta ptr1 + 1            ; restore to ptr1 hi
            pla                     ; enemy address lo part
            sta ptr1                ; restore to ptr1 lo

            ldy #Enemy::sprite      ; offset to sprite field
            lda ptr2                ; sprite addr lo byte
            sta (ptr1),y            ; write to sprite field lo
            iny
            lda ptr2 + 1            ; sprite addr hi byte
            sta (ptr1),y            ; write to sprite field hi

            rts
.endproc


;
; Tick enemies.
;
; Iterates all enemy objects and performs collision detection, movement and
; rendering.
;
.proc tick_enemies

.mac tick_enemy
            ldy #Enemy::kind
            lda (tmp1),y            ; load 'kind' attribute
            beq @end                ; skip this enemy if zero

            ldy #Enemy::hits
            lda (tmp1),y            ; load 'hits' attribute
            beq @end                ; skip if this enemy wasn't hit

            ldy #Enemy::sprite
            lda (tmp1),y
            sta ptr1                ; 'sprite' lo to ptr1
            iny
            lda (tmp1),y
            sta ptr1 + 1            ; 'sprite' hi to ptr1 + 1
            jsr destroy_sprite      ; destroy the sprite associated with the enemy
            lda #$cc
            fill_mem tmp1, .sizeof(Enemy), #0   ; zero the enemy record
@end:
.endmac

            lda #<enemies
            sta tmp1
            lda #>enemies
            sta tmp2
            iter_ptr tmp1, enemies_end, .sizeof(Enemy), tick_enemy

            rts
.endproc
