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


load_sprite_color_palettes:
    ;
    ; Set sprite-0 palette
    ;
    ; set PPUADDR destination address to Sprite Palette 0 ($3F11)
    lda #>VRAM_SPR_PAL0
    sta PPUADDR
    lda #<VRAM_SPR_PAL0
    sta PPUADDR

    ldx #$00
@sprite_palette_load_loop:
    lda sprite_palettes, x                  ; first color palettes
    sta PPUDATA                    ; write the color indices
    inx
    cpx #$10                                ; load all 4 sprite palettes
    bne @sprite_palette_load_loop
    rts


load_background_palettes:
    ;
    ; Set ppu data pointer to the address of the background palette 0
    ; and fill all following color palettes
    ;
    lda #>VRAM_BGR_PAL0
    sta PPUADDR
    lda #<VRAM_BGR_PAL0
    sta PPUADDR

    ldx #$00
@bg_palette_load_loop:
    lda background_palettes, x              ; first color palettes
    sta PPUDATA                    ; write the color indices
    inx
    cpx #$10                                ; load all 4 sprite palettes
    bne @bg_palette_load_loop
    rts