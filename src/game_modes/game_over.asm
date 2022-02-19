.include "globals.asm"

.import create_sprite
.import destroy_sprites


.rodata
;
; Game Over mode descriptor.
;
game_over_mode:
    .addr game_over_init
    .addr game_over_fini
    .addr game_over_tick

.export game_over_mode

rainbow_anim:
    .byte $01   ; length frames
    .byte $00   ; speed
    .byte $64   ; starting tile ID
    .byte $02   ; attribute set
    .byte $02   ; padding x, z -> 2 tiles wide and high


.code
;
; Initialziation subroutine.
;
.proc game_over_init
            ;
            ; Create the rainbow sprite
            ;
            lda #130                ; xPos
            sta var1
            lda #$b4                ; yPos
            sta var2
            lda #<rainbow_anim
            sta ptr1                ; ptr1 lo = rainbow animation descriptor lo
            lda #>rainbow_anim
            sta ptr1 + 1            ; ptr1 hi = rainbow animation descriptor hi
            jsr create_sprite       ; create the rainbow sprite

            rts
.endproc

;
; Cleanup subroutine.
;
.proc game_over_fini
            jsr destroy_sprites

            rts
.endproc

;
; Game mode tick subroutine.
;
.proc game_over_tick
            rts
.endproc
