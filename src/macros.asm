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
.macro mult m1, m2, output
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