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
.macro mult_constant m1, m2, output
    lda m1
    pha 
    lda #$00
    sta output
:
    lda output
    clc
    adc m2
    sta output
    dec m1
    lda m1
    cmp #$00
    bne :-
    pla
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
    lda output
    clc
    adc m2
    sta output
    dec m1
    lda m1
    cmp #$00
    bne :-
    pla
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