;
; Memory-mapped PPU registers
;
PPUSTAT = $2002         ; PPU status register
PPUSCRL = $2005         ; PPU scroll register (x2 writes for X and Y)
PPUADDR = $2006         ; VRAM write address register
PPUDATA = $2007         ; VRAM write data register

;
; PPU VRAM mapping
;
VRAM_BGCOLOR = $3f00    ; Universal background color
VRAM_BGR_PAL0 = $3f01   ; Background palette 0
VRAM_BGR_PAL1 = $3f05   ; Background palette 1
VRAM_BGR_PAL2 = $3f09   ; Background palette 2
VRAM_BGR_PAL3 = $3f0d   ; Background palette 3
VRAM_SPR_PAL0 = $3f11   ; Sprite palette 0
VRAM_SPR_PAL1 = $3f15   ; Sprite palette 1
VRAM_SPR_PAL2 = $3f19   ; Sprite palette 2
VRAM_SPR_PAL3 = $3f1d   ; Sprite palette 3
VRAM_NAMETABLE0 = $2000 ; Nametable 0
VRAM_NAMETABLE1 = $2400 ; Nametable 1
VRAM_NAMETABLE2 = $2800 ; Nametable 2
VRAM_NAMETABLE3 = $2c00 ; Nametable 3
VRAM_ATTRTABLE0 = $23c0 ; Attribute table 0
VRAM_ATTRTABLE1 = $27c0 ; Attribute table 1
VRAM_ATTRTABLE2 = $2bc0 ; Attribute table 2
VRAM_ATTRTABLE3 = $2fc0 ; Attribute table 3
