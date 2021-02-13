;
; Universal background color
;
BG_COLOR = $0d

;
; Background tiles palette indices
;
background_palettes:
    .byte $10, $30, $20, $0d
    .byte $04, $14, $24, $0d 
    .byte $04, $14, $24, $0d
    .byte $04, $14, $24, $0d

;
; sprite palette indices
; 
sprite_palettes:
    .byte $02, $22, $32, $0d
    .byte $16, $26, $37, $0d
    .byte $04, $15, $35, $0d
    .byte $04, $14, $24, $0d

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load sprite palettes
;
; X-stack arguments:
;   NUM_COLORS           - num colors to read out from the palette (default 16)
;   VRAM_PAL_ADDR_HI     - Palette PPU destination address high part
;   VRAM_PAL_ADDR_LO     - Palette PPU destination address low part
;   PALETTE_ADDR_LO      - Palette address high part
;   PALETTE_ADDR_HI      - Palette adress address low part
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load_color_palettes:             
    inx                                 ; load number of colors to load and store it in y
    ldy $00,X
                            
    ; set PPUADDR destination address to Palette
    inx                                 ; X => VRAM_PAL_ADDR_HI
    lda $00,X
    sta PPUADDR

    inx                                 ; X => VRAM_PAL_ADDR_LO
    lda $00,X
    sta PPUADDR

    inx                                 ; X => PALETTE_ADDR_LO
@palette_load_loop:
    lda ($00,X)                         ; X points to PALETTE_ADDR_LO, therfore loads lo, hi
    sta PPUDATA                         ; write the color indices
    inc $00,X                           ; increase the low address part -> point to next color

    bne :+                              ; check for overflow (ff -> 00)
    inx                                 
    inc $00,X                           ; increase the address of the high pointer PALETTE_ADDR_HI
    dex                                 ; go back to lo pointer X to PALETTE_ADDR_LO

:   dey
    cpy #$00                           ; check if all colors are loaded, if not, continue
    bne @palette_load_loop
    inx
    rts