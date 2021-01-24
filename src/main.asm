MESSAGE_Y = $78
MESSAGE_X = $50

.segment "INESHDR"
    .byt "NES",$1A  ; magic signature
    .byt 1          ; PRG ROM size in 16384 byte units
    .byt 1          ; CHR ROM size in 8192 byte units
    .byt $00        ; mirroring type and mapper number lower nibble
    .byt $00        ; mapper number upper nibble


.rodata
message:
    .byt "Hello World!", $00


.zeropage
frame_counter: .res 1
odd_frame_flag: .res 1


;
; PPU Object Attribute Memory - shadow memory which holds rendering attributes
; of up to 64 sprites
.segment "OAM"
oam:
    .res 256


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

    ; Set destination OAM address
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
@advance_character:

    ; set Y coord (or hide the character by setting it to $ff)
    txa
    and #$1
    sta odd_frame_flag
    lda frame_counter
    and #$1
    eor odd_frame_flag

    bne @hide_char
    lda #MESSAGE_Y
    sta oam,Y
    iny
    jmp @set_x

@hide_char:
    lda #$ff
    sta oam,Y
    iny

    ; set sprite index based on character value or break loop on NUL-terminator
@set_x:
    lda message,X
    cmp #$0
    beq main
    sta oam,Y
    iny

    ; set sprite attrs
    lda #$00
    sta oam,Y
    iny

    ; increment X coord by 8 * <X reg>
    txa
    pha
    lda #MESSAGE_X
@add:
    dex
    bmi @end
    adc #$08
    jmp @add
@end:
    sta oam,Y
    pla
    tax
    iny

    ; go to next character
    inx
    jmp @advance_character

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

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "DATA"
.incbin "../assets/chr_sheet.chr"
