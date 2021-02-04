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
    .byte $04, $14, $24, $0d
    .byte $04, $14, $24, $0d


PPU_DATA_STORAGE = $2007

load_sprite_color_palettes:
    ldx #$00
@sprite_palette_load_loop:
    lda sprite_palettes, x                  ; first color palettes
    sta PPU_DATA_STORAGE                    ; write the color indices
    inx
    cpx #$10                                ; load all 4 sprite palettes
    bne @sprite_palette_load_loop
    rts


load_background_palettes:
    ldx #$00
@bg_palette_load_loop:
    lda background_palettes, x              ; first color palettes
    sta PPU_DATA_STORAGE                    ; write the color indices
    inx
    cpx #$10                                ; load all 4 sprite palettes
    bne @bg_palette_load_loop
    rts