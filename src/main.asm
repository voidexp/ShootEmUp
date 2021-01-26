PLAYER_START_X = $58    ; Player start X coord
PLAYER_START_Y = $74    ; Player start Y coord

BGCOLOR = $0d           ; Overall background color index
PLCOLOR = $062636       ; Player palette color indices

PPUADDR = $2006         ; VRAM write address register
PPUDATA = $2007         ; VRAM write data register

VRAM_BGCOLOR = $3f00    ; Universal background color
VRAM_BGR_PAL0 = $3f01   ; Background palette 0
VRAM_BGR_PAL1 = $3f05   ; Background palette 1
VRAM_BGR_PAL2 = $3f09   ; Background palette 2
VRAM_BGR_PAL3 = $3f0d   ; Background palette 3
VRAM_SPR_PAL0 = $3f11   ; Sprite palette 0
VRAM_SPR_PAL1 = $3f15   ; Sprite palette 1
VRAM_SPR_PAL2 = $3f19   ; Sprite palette 2
VRAM_SPR_PAL3 = $3f1d   ; Sprite palette 3


;
; iNES header for the emulators.
;
.segment "INESHDR"
    .byt "NES",$1A  ; magic signature
    .byt 1          ; PRG ROM size in 16384 byte units
    .byt 1          ; CHR ROM size in 8192 byte units
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


;
; Zero-page RAM.
;
.zeropage
    frame_counter: .res 1   ; current frame, wraps at $ff


;
; PPU Object Attribute Memory - shadow RAM which holds rendering attributes
; of up to 64 sprites.
;
.segment "OAM"
oam:
    .res 256


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
    ; Set sprite-0 palette
    ;
    ; Set PPUADDR destination address to Sprite Palette 0 ($3F11)
    lda #>VRAM_SPR_PAL0
    sta PPUADDR
    lda #<VRAM_SPR_PAL0
    sta PPUADDR

    ; Write each of the three palette colors.
    ; NOTE: each writethis advances the PPUDATA address by 1 byte
    lda #(PLCOLOR >> 16)
    sta PPUDATA
    lda #(PLCOLOR >> 8) & $ff
    sta PPUDATA
    lda #(PLCOLOR) & $ff
    sta PPUDATA

    ; Clear OAMDATA address
    lda #$00
    sta $2003

    ; Enable sprite drawing
    lda #$10
    sta $2001

    ; Ready to go, enable VBlank NMI
    lda #$80
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
    ; sprite $00
    ;
    ; Y coord
    txa
    lda #PLAYER_START_Y
    sta oam,Y
    iny
    ; sprite id
    lda #$00
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
    lda #$01
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
    lda #$10
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
    lda #$11
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

    ; Perform DMA copy of shadow OAM to PPU's OAM
    lda #>oam
    sta $4014

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
