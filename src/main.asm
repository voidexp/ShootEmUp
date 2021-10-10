.include "nes.asm"
.include "constants.asm"
.include "macros.asm"
.include "structs.asm"
.include "globals.asm"

.import background_palettes
.import copy_to_vram
.import draw_sprites
.import load_color_palettes
.import poll_joypads
.import sprite_palettes
.import shooter_mode


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

    starfield2: .incbin "../build/levels/starfield.lvl"
    starfield2_end:


.code
;
; Execution entry point. After power-on and initial boot, the CPU jumps here.
;
reset_handler:
            sei                     ; ignore IRQs
            cld                     ; disable decimal mode
            ldx #$40
            stx $4017               ; disable APU frame IRQ
            ldx #$ff
            txs                     ; Set up stack
            inx                     ; now X = 0 (FF overflows)
            stx $2000               ; disable NMI
            stx $2001               ; disable rendering
            stx $4010               ; disable DMC IRQs

            ; Optional (omitted):
            ; Set up mapper and jmp to further init code here.

            ; The vblank flag is in an unknown state after reset, so it is
            ; cleared here to make sure that vblankwait1 does not exit
            ; immediately.

            ; NOTE: reading $2002 clears the 7th bit, so, testing it effectively
            ; clears it.
            bit $2002

            ; First of two waits for vertical blank to make sure that the PPU
            ; has stabilized
vblankwait1:
            bit $2002
            bpl vblankwait1

            ; We now have about 30,000 cycles to burn before the PPU stabilizes.
            ; One thing we can do with this time is put our 2k of RAM in a known
            ; state. Here we fill it with $00, which matches what (say) a C
            ; compiler expects for BSS. Conveniently, X is still 0.
            txa
clrmem:     sta $000,x
            sta $100,x
            sta $200,x
            sta $300,x
            sta $400,x
            sta $500,x
            sta $600,x
            sta $700,x
            inx
            bne clrmem

            ; Other things you can do between vblank waits are set up audio or
            ; set up other mapper registers.

            ; Second of the two vblank waits. After this, we're ready to go.
vblankwait2:
            bit $2002
            bpl vblankwait2

            ;
            ; Initialization section.
            ;
            ; PPU warm-up is done, finally we can do prepare our stuff,
            ; initialize subystems, load levels, spawn enemies, etc.
            ; All covered by a nice black screen.
            ;

            ; Set initial game mode
            lda #<shooter_mode
            sta game_mode
            lda #>shooter_mode
            sta game_mode + 1

            ; Initialize the game mode
            ldy #GameMode::init
            lda (game_mode),y
            sta ptr1                ; ptr1 lo = init() lo
            iny
            lda (game_mode),y
            sta ptr1 + 1            ; ptr1 hi = init() hi
            call_ptr ptr1           ; call the game mode init() subroutine pointed to by ptr1

            ;
            ; Here we setup the PPU for drawing by writing apropriate
            ; memory-mapped registers and specific memory locations.
            ;
            ; IMPORTANT! Writes to the PPU RAM afterwards should occur only
            ; during VBlank!
            ;
            ; First set the universal background color
            lda #>VRAM_BGCOLOR
            sta PPUADDR
            lda #<VRAM_BGCOLOR
            sta PPUADDR

            lda #BG_COLOR
            sta PPUDATA

            ; write the background palette color indices
            lda #>background_palettes; PALETTE_ADDR_HI
            sta $00,X
            dex
            lda #<background_palettes; PALETTE_ADDR_LO
            sta $00,X
            dex
            lda #<VRAM_BGR_PAL0     ; VRAM_PAL_ADDR_LO
            sta $00,X
            dex
            lda #>VRAM_BGR_PAL0     ; VRAM_PAL_ADDR_HI
            sta $00,X
            dex
            lda #$10                ; NUM_COLORS
            sta $00,X
            dex
            jsr load_color_palettes

            ; write the sprite palette color indices
            lda #>sprite_palettes   ; PALETTE_ADDR_HI
            sta $00,X
            dex
            lda #<sprite_palettes   ; PALETTE_ADDR_LO
            sta $00,X
            dex
            lda #<VRAM_SPR_PAL0     ; VRAM_PAL_ADDR_LO
            sta $00,X
            dex
            lda #>VRAM_SPR_PAL0     ; VRAM_PAL_ADDR_HI
            sta $00,X
            dex
            lda #$10                ; NUM_COLORS
            sta $00,X
            dex
            jsr load_color_palettes

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
            ; Clear PPU status and scroll registers
            ;
            bit PPUSTAT
            lda #$00
            sta PPUSCRL
            sta PPUSCRL

            ; Clear OAMDATA address
            lda #$00
            sta OAMADDR

            ; Enable sprite drawing
            lda #$1e
            sta PPUMASK

            ; Ready to go, enable VBlank NMI, all subsequent writes should take
            ; place during VBlank, inside NMI handler.
            lda #$90
            sta PPUCTRL

            ;
            ; Finally, the never ending Main Loop!
            ;
            ; All simulation, game logic, advancing animations, moving stuff
            ; around, bank switching and whatever else makes up the actual game
            ; goes here.
            ;
            ; NOTE: this is executed *in parallel* with the PPU. Actual writes
            ; to PPU registers, DMA and everything else should occur *only* in
            ; the NMI handler during VBlank!
            ;
main:
            jsr wait_frame
            jsr poll_joypads

            ;
            ; Tick the current game mode
            ;
            ldy #GameMode::tick
            lda (game_mode),y
            sta ptr1                ; ptr1 lo = tick() lo
            iny
            lda (game_mode),y
            sta ptr1 + 1            ; ptr1 hi = tick() hi
            call_ptr ptr1           ; call the tick() subroutine pointed to by ptr1

            jsr draw_sprites

            ;
            ; Switch game mode, if needed
            ;
            lda next_game_mode + 1  ; check next game mode hi
            beq :+                  ; if zero, skip over
            ldy #GameMode::fini
            lda (game_mode),y
            sta ptr1                ; ptr1 lo = fini() lo
            iny
            lda (game_mode),y
            sta ptr1 + 1            ; ptr1 hi = fini() hi
            call_ptr ptr1           ; invoke fini() subroutine of the current game mode
            lda next_game_mode
            sta game_mode           ; copy next lo
            lda next_game_mode + 1
            sta game_mode + 1       ; copy next
            lda #0
            sta next_game_mode      ; clear next lo
            sta next_game_mode + 1  ; clear next hi
            ldy #GameMode::init
            lda (game_mode),y
            sta ptr1                ; ptr1 lo = init() lo
            iny
            lda (game_mode),y
            sta ptr1 + 1            ; ptr1 hi = init() hi
            call_ptr ptr1           ; invoke init() subroutine of the new game mode

:           jmp main                ; loop forever


;
; Wait for a new frame.
;
.proc wait_frame
            inc sleeping            ; set sleeping flag, the PPU will clear it
@loop:      lda sleeping            ; if sleeping is zero, Z flag will be set
            bne @loop               ; loop until the flag is cleared by the PPU
            rts
.endproc


;
; PPU vblank Non-Masked Interrupt handler.
;
; Executed by the CPU when the PPU signals that vblank period has started.
;
; Note that we must make sure that all this code takes less than ~2250 cycles to
; execute.
nmi_handler:
            ; push registers to stack
            pha
            txa
            pha
            tya
            pha

            ; clear the frame waiting flag
            lda #0
            sta sleeping

            ; scroll up the Y axis
            lda scroll_y
            bne :+
            ; WTF?! just figured out this number empirically, but why it's
            ; needed in first place?
            sbc #$0f
:           sbc #$01
            sta scroll_y

            ; perform DMA copy of shadow OAM to PPU's OAM
            lda #>oam
            sta $4014

            ; set scroll, what pixel of the NT should be on the left top of the
            ; screen
            lda #0
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
