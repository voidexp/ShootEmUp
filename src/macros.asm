; split byte in two 4 bit values 2x 0-15
.macro split_byte input, output1, output2
    lda input
    and #$0f
    sta output1
    lda input
    lsr
    lsr
    lsr
    sta output2
.endmacro

.macro extract_low input, output
    lda input
    and #$0f
    sta output1
.endmacro


.macro extract_hi input, output
    lda input
    and #$f0
    lsr
    lsr
    lsr
    sta output2
.endmacro

; first address
; second constant
; third address
.macro mult_with_constant m1, m2, output
    lda m1
    pha
    lda #$00
    sta output
:
    lda m1
    cmp #$00
    beq :+
    lda output
    clc
    adc m2
    sta output
    dec m1
    jmp :-
:   pla
    sta m1
.endmacro

; first address
; second address
; third address
.macro mult_variables m1, m2, output
    lda m1
    pha
    lda m2
    pha
    lda #$00
    sta output
:
    lda m1
    cmp #$00
    beq :+
    lda output
    clc
    adc m2
    sta output
    dec m1
    jmp :-
:   pla
    sta m2
    pla
    sta m1
.endmacro

.macro copy_x_bytes_zp src, offset_src, dst, offset_dst, num
    lda offset_src
    clc
    adc num
    tay ; store offset at y .. start with highest element to put on stack

:
    dey
    lda (src), y
    pha
    cpy offset_src
    bne :-
    ldx num
    ldy offset_dst
:
    dex
    pla
    sta (dst), y
    iny
    cpx #$00
    bne :-
.endmacro

.macro calc_address_with_offset address, offset, target
    lda #<address              ; low byte
    sta target

    lda #>address              ; high byte
    sta target + 1

    ldy offset
    cpy #$00
    beq @continue
    ldx #$00
    @loop:
        dey                 ; decrease remaining steps
        inc target,X        ; increase the low address part

        bne @continue      ; advance page on overflow, else skip to @continue

        inx                 ; let X point to SRC_HI
        inc target,X        ; increase SRC_HI, ignore overflow
        dex                 ; restore X to SRC_LO

    @continue:
        cpy #$00
        bne @loop           ; go over again
.endmacro

.macro get_num_of_bits_set_in_mask mask, num
    ; push mask value to stack
    lda #$00
    sta num
    ldy #$08
@loop:
    LDA #$01
    BIT mask
    BEQ :+
    INC num
:
    lda mask
    lsr
    sta mask
    dey
    cpy #$00
    bne @loop
.endmacro

;
; Iterate a pointer with fixed increments.
;
.macro iter_ptr ptr, address, increment, body
@loop:      lda ptr             ; load the low address
            cmp #<address       ; compare it with target low part
            bne @body           ; if doesnt match; execute teh body
            lda ptr + 1         ; load high address
            cmp #>address       ; compare with target high part
            beq @end            ; if match, we're done
@body:      body                ; inlined code macro
            lda ptr             ; re-load the pointer
            clc
            adc #increment      ; increment the low part
            sta ptr             ; write it back
            bcc @loop           ; repeat if no overflow occurred
            lda ptr + 1         ; load the high part
            adc 0               ; add carry
            sta ptr + 1         ; write it back
            bcc @loop           ; repeat
@end:
.endmacro
