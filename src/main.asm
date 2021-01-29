.include "nes.asm"

.import copy_to_vram

PLAYER_START_X = $58    ; Player start X coord
PLAYER_START_Y = $74    ; Player start Y coord

BGCOLOR =  $0d          ; Overall background color index
BGR_PAL0 = $103020      ; Background 0 tiles palette indices
PLCOLOR =  $062636      ; Player palette color indices


;
; iNES header for the emulators.
;
.segment "INESHDR"
    .byt "NES",$1A  ; magic signature
    .byt 1          ; PRG ROM size in 16384 byte units
    .byt 2          ; CHR ROM size in 8192 byte units
    .byt $00        ; mirroring type and mapper number lower nibble
    .byt $00        ; mapper number upper nibble


;
; CHR-ROM, accessible by the PPU
;
.segment "CHR1"
.incbin "../build/ships.chr"

.segment "CHR2"
.incbin "../build/background.chr"


;
; PRG-ROM, read-only data
;
.rodata
    starfield1: .incbin "../build/levels/starfield.lvl"
    starfield1_end:

    starfield2: .incbin "../build/levels/starfield2.lvl"
    starfield2_end:

;
; Zero-page RAM.
;
.zeropage
    frame_counter:  .res 1  ; current frame, wraps at $ff

    ; scroll
    scroll_y:       .res 1
    scroll_x:       .res 1

;
; PPU Object Attribute Memory - shadow RAM which holds rendering attributes
; of up to 64 sprites.
;
.segment "OAM"
    oam: .res 256


;
; PRG-ROM, code.
;
.code
reset_handler:
    sei        ; ignore IRQs
    cld        ; disable decimal mode
    ldx #$40
    stx $4017  ; disable APU frame IRQ
    ldx #$ff
    txs        ; Set up stack
    inx        ; now X = 0 (FF overflows)
    stx $2000  ; disable NMI
    stx $2001  ; disable rendering
    stx $4010  ; disable DMC IRQs

    ; Optional (omitted):
    ; Set up mapper and jmp to further init code here.

    ; The vblank flag is in an unknown state after reset,
    ; so it is cleared here to make sure that vblankwait1
    ; does not exit immediately.

    ; NOTE: reading $2002 clears the 7th bit, so, testing it effectively clears
    ; it.
    bit $2002

    ; First of two waits for vertical blank to make sure that the
    ; PPU has stabilized
vblankwait1:
    bit $2002
    bpl vblankwait1

    ; We now have about 30,000 cycles to burn before the PPU stabilizes.
    ; One thing we can do with this time is put RAM in a known state.
    ; Here we fill it with $00, which matches what (say) a C compiler
    ; expects for BSS.  Conveniently, X is still 0.
    txa
clrmem:
    sta $000,x
    sta $100,x
    sta $200,x
    sta $300,x
    sta $400,x
    sta $500,x
    sta $600,x
    sta $700,x
    inx
    bne clrmem

    ; Other things you can do between vblank waits are set up audio
    ; or set up other mapper registers.

vblankwait2:
    bit $2002
    bpl vblankwait2


ready:
    ; init the X-stack to the end of the zeropage RAM
    ldx #$ff

;
; Here we setup the PPU for drawing by writing apropriate memory-mapped
; registers and specific memory locations.
;
; IMPORTANT! Writes to the PPU RAM afterwards should occur only during VBlank!
;
ppusetup:
    ;
    ; Set universal background color
    ;
    ; set PPUADDR
    lda #>VRAM_BGCOLOR
    sta PPUADDR
    lda #<VRAM_BGCOLOR
    sta PPUADDR
    ; write the color index
    lda #BGCOLOR
    sta PPUDATA

    ;
    ; Set background-0 palette
    ;
    lda #>VRAM_BGR_PAL0
    sta PPUADDR
    lda #<VRAM_BGR_PAL0
    sta PPUADDR
    ; write the color indices
    lda #(BGR_PAL0 >> 16)
    sta PPUDATA
    lda #(BGR_PAL0 >> 8) & $ff
    sta PPUDATA
    lda #(BGR_PAL0 & $ff)
    sta PPUDATA

    ;
    ; Populate nametable-0 with starfield1 stored in PRG-ROM
    ;
    size1 = starfield1_end - starfield1
    lda #size1 & $ff        ; SIZE_LO
    sta $00,X
    dex
    lda #size1 >> 8         ; SIZE_HI
    sta $00,X
    dex
    lda #>starfield1        ; SRC_HI
    sta $00,X
    dex
    lda #<starfield1        ; SRC_LO
    sta $00,X
    dex
    lda #<VRAM_NAMETABLE0   ; VRAM_LO
    sta $00,X
    dex
    lda #>VRAM_NAMETABLE0   ; VRAM_HI
    sta $00,X
    dex

    jsr copy_to_vram

    ;
    ; Populate nametable-2 with starfield2 stored in PRG-ROM
    ;
    size2 = starfield2_end - starfield2
    lda #size2 & $ff        ; SIZE_LO
    sta $00,X
    dex
    lda #size2 >> 8         ; SIZE_HI
    sta $00,X
    dex
    lda #>starfield2        ; SRC_HI
    sta $00,X
    dex
    lda #<starfield2        ; SRC_LO
    sta $00,X
    dex
    lda #<VRAM_NAMETABLE2   ; VRAM_LO
    sta $00,X
    dex
    lda #>VRAM_NAMETABLE2   ; VRAM_HI
    sta $00,X
    dex

    jsr copy_to_vram

    ;
    ; Set sprite-0 palette
    ;
    ; set PPUADDR destination address to Sprite Palette 0 ($3F11)
    lda #>VRAM_SPR_PAL0
    sta PPUADDR
    lda #<VRAM_SPR_PAL0
    sta PPUADDR
    ; write each of the three palette colors.
    lda #(PLCOLOR >> 16)
    sta PPUDATA
    lda #(PLCOLOR >> 8) & $ff
    sta PPUDATA
    lda #(PLCOLOR) & $ff
    sta PPUDATA

    ;
    ; Clear PPU status and scroll registers
    ;
    bit PPUSTAT
    lda #$00
    sta PPUSCRL
    sta PPUSCRL

    ; Clear OAMDATA address
    lda #$00
    sta $2003

    ; Enable sprite drawing
    lda #$1e
    sta $2001

    ; Ready to go, enable VBlank NMI, all subsequent writes should take place
    ; during VBlank, inside NMI handler.
    lda #$90
	sta $2000

main:
    ;
    ; Display the message on screen using sprites representing ASCII symbols
    ;
    ldx #$00 ; character index
    ldy #$00 ; byte offset

draw_player:
    ;
    ; Player ship is made up of 4 sprites in a 2x2 box, as below following:
    ; +--+--+
    ; |00|01|
    ; +--+--+
    ; |10|11|
    ; +--+--+

    ;;; TODO: rework this into some kind of loop ;;;

    ;
    ; Sprite $00
    ;
    ; Y coord
    txa
    lda #PLAYER_START_Y
    sta oam,Y
    iny
    ; sprite id
    lda #$01
    sta oam,Y
    iny
    ; sprite attrs
    lda #$00
    sta oam,Y
    iny
    ; X coord
    lda #PLAYER_START_Y
    sta oam,Y
    iny

    ;
    ; sprite $01
    ;
    ; Y coord
    txa
    lda #PLAYER_START_Y
    sta oam,Y
    iny
    ; sprite id
    lda #$02
    sta oam,Y
    iny
    ; sprite attrs
    lda #$00
    sta oam,Y
    iny
    ; X coord
    lda #PLAYER_START_Y + $08
    sta oam,Y
    iny

    ;
    ; sprite $10
    ;
    ; Y coord
    txa
    lda #PLAYER_START_Y + $08
    sta oam,Y
    iny
    ; sprite id
    lda #$11
    sta oam,Y
    iny
    ; sprite attrs
    lda #$00
    sta oam,Y
    iny
    ; X coord
    lda #PLAYER_START_Y
    sta oam,Y
    iny

    ;
    ; sprite $11
    ;
    ; Y coord
    txa
    lda #PLAYER_START_Y + $08
    sta oam,Y
    iny
    ; sprite id
    lda #$12
    sta oam,Y
    iny
    ; sprite attrs
    lda #$00
    sta oam,Y
    iny
    ; X coord
    lda #PLAYER_START_Y + $08
    sta oam,Y
    iny

    jmp main

;
; Handle non-masked interrupts
;
nmi_handler:
    ; push registers to stack
    pha
    txa
    pha
    tya
    pha

    ; increment the frame counter
    inc frame_counter

    ; scroll up the Y axis
    lda scroll_y
    bne :+
    sbc #$0f        ; wtf?! just figured out this number empirically, but why
                    ; it's needed in first place?
:   sbc #$01
    sta scroll_y

    ; Perform DMA copy of shadow OAM to PPU's OAM
    lda #>oam
    sta $4014

    ; set scroll
    lda scroll_x
    sta PPUSCRL
    lda scroll_y
    sta PPUSCRL

    ; restore the registers
    pla
    tay
    pla
    tax
    pla

    rti

;
; Handle IRQs
;
irq_handler:
    rti


;
; Interrupt handler vectors (pointers).
; Three 16 bit addresses to, respectively, the NMI, RESET and IRQ handlers.
;
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
