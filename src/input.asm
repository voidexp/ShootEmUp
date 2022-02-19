.include "globals.asm"
.include "nes.asm"

.export poll_joypads

;
; Poll joypads.
;
; Pressed button bits are written to `pad1` and `pad2` zeropage locations.
;
; Adapted from https://wiki.nesdev.org/w/index.php?title=Controller_reading_code
;
.proc poll_joypads
            lda #$01
            sta JOYPAD1
            sta pad2                ; player 2's buttons double as a ring counter
            lsr a                   ; now A is 0
            sta JOYPAD1
@loop:
            lda JOYPAD1
            and #%00000011          ; ignore bits other than controller
            cmp #$01                ; Set carry if and only if nonzero
            rol pad1                ; Carry -> bit 0; bit 7 -> Carry
            lda JOYPAD2             ; Repeat
            and #%00000011
            cmp #$01
            rol pad2                ; Carry -> bit 0; bit 7 -> Carry
            bcc @loop
            rts
.endproc
