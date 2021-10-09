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
; Fill memory area with given value.
;
; At most 255 bytes long regions are accepted.
;
; Parameters:
;   ptr     - pointer to the memory region start
;   len     - length in bytes, at most 255
;   expr    - fill value expression (immediate or address)
;
.macro fill_mem ptr, len, expr
            .local @clr
            ldy #0
            lda expr
@clr:       sta (ptr),y
            iny
            cpy #len
            bne @clr
.endmacro

;
; Iterate a pointer with fixed increments.
;
.macro iter_ptr ptr, end, offset, pred
            .local @loop
            .local @body
@loop:      lda ptr             ; load the low address
            cmp #<end           ; compare it with target low part
            bne @body           ; if doesnt match, execute the body
            lda ptr + 1         ; load high address
            cmp #>end           ; compare with target high part
            bne @body           ; if doesn't match, execute the body
            jmp @exit           ; otherwise do a long jump to the exit
@body:      pred                ; inlined code macro
            lda ptr             ; re-load the pointer
            clc
            adc #offset         ; increment the low part
            sta ptr             ; write it back
            bcs :+              ; repeat if no overflow occurred
            jmp @loop
:           lda ptr + 1         ; load the high part
            adc 0               ; add carry
            sta ptr + 1         ; write it back
            bcs @exit           ; repeat
            jmp @body
@exit:
.endmacro


;
; Iterate a pointer over an array until Z flag is not set.
;
; Parameters:
;   ptr     - iterator
;   end     - end address (excluded)
;   offset  - iteration offset
;   pred    - predicate macro to execute on each iteration;
;             should set Z flag as true condition
;
.macro find_ptr ptr, end, offset, pred
@loop:
    lda ptr
    cmp #<end
    bne @body
    lda ptr + 1
    cmp #>end
    beq @not_found

@body:
    pred
    beq @exit

    lda ptr
    clc
    adc #offset
    sta ptr
    bcc @loop
    lda ptr + 1
    adc 0
    sta ptr + 1
    bcc @loop
@not_found:
    lda #$ff
@exit:
.endmacro


;
; Invoke a subroutine via a pointer.
;
; Parameters:
;   ptr     - pointer holding the address of the subroutine to call
;
.macro call_ptr ptr
            .local @retaddr
            lda #>(@retaddr - 1)
            pha
            lda #<(@retaddr - 1)
            pha
            jmp (ptr)
@retaddr:
.endmacro
