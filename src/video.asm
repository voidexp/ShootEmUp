.export copy_to_vram

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copy given memory region to VRAM
;
; X-stack arguments:
;   VRAM_HI     - VRAM destination address high part
;   VRAM_LO     - VRAM destination address low part
;   SRC_LO      - RAM source address low part
;   SRC_HI      - RAM source address high part
;   SIZE_HI     - Most significant size byte
;   SIZE_LO     - Least significant size byte
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc copy_to_vram
    ; pop from X-stack VRAM hi and lo address parts and write them to PPUADDR
    inx         ; X => VRAM_HI
    lda $00,X
    sta PPUADDR
    inx         ; X => VRAM_LO
    lda $00,X
    sta PPUADDR

    inx ; X => SRC_LO
    inx ; X => SRC_HI
    inx ; X => SIZE_HI

    ; copy SIZE_HI to A and push it to the stack, this will be the page counter
    lda $00,X
    pha

    inx ; X => SIZE_LO

    ; copy SIZE_LO to Y, this will be the byte counter
    ldy $00,X

    ; restore X to SRC_LO
    dex
    dex
    dex

    ; write to PPUDATA byte-by-byte in a loop
    @loop:
        lda ($00,X)     ; X points to SRC_LO, load (SRC_LO,SRC_HI) to A
        sta PPUDATA     ; write it to VRAM, this advances PPUADDR by 1
        inc $00,X       ; increase the low address part
        bne @declosize  ; advance page on overflow, else skip to @declosize

        inx             ; let X point to SRC_HI
        inc $00,X       ; increase SRC_HI, ignore overflow (auto-mirroring)
        dex             ; restore X to SRC_LO

        @declosize:
        dey             ; one less byte to copy!
        cpy #$ff
        beq @dechisize  ; if overflown, this page is done, go to @dechisize
        jmp @loop       ; go over again

        @dechisize:
        pla             ; get current page counter from stack
        beq @end        ; if zero, we're done
        sbc #$1         ; decrease page counter
        pha             ; push it back to stack
        jmp @loop

    @end:
    ; X => SRC_LO, pull all the remaining arguments from the X-stack
    inx
    inx
    inx

    rts
.endproc
