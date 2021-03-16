.include "nes.asm"
.include "globals.asm"
.include "color_settings.asm"
.include "video.asm"
.include "macros.asm"

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

; Zero-page RAM.
;
.zeropage
    frame_counter:      .res 1  ; current frame, wraps at $ff

    ; moving player
    player_speed:       .res 1  ; current player speed
    player_direction:   .res 1  ; current direction bit set  (0000 LEFT DOWN RIGHT UP)
    player_pos_x:       .res 1  ; Player start X coord
    player_pos_y:       .res 1  ; Player start Y coord

    ; scroll
    scroll_y:           .res 1
    scroll_x:           .res 1

    ; draw flags
    update_flags:       .res 1  ; flags what to update (0000 000 UPDATE_POSITIONS)
    draw_flags:  	    .res 1  ; flags what to draw in the next frame (0000 000 DRAW_FLAME)
    update_animations:  .res 1  ; update animations

    ; tmp variables
    temp_1:             .res 1
    temp_2:             .res 1
    temp_3:             .res 1
    temp_4:             .res 1
    temp_5:             .res 1
    temp_6:             .res 1

    var_1:              .res 1
    var_2:              .res 1
    var_3:              .res 1
    var_4:              .res 1
    var_5:              .res 1
    var_6:              .res 1
    var_7:              .res 1
    var_8:              .res 1
    var_9:              .res 1
    var_10:             .res 1

    ; temp_address
    address_1:          .res 2
    address_2:          .res 2  
    address_3:          .res 2
    address_4:          .res 2
    address_5:          .res 2
    address_6:          .res 2
    address_7:          .res 2
    address_8:          .res 2
    address_9:          .res 2
    address_10:         .res 2

    ; game mode stuff
    kill_count:         .res 1
    shoot_cooldown:     .res 1
    num_enemies_alive:  .res 1

.include "animation.asm"
.include "components/health.asm"
.include "components/movement.asm"
.include "components/sprite.asm"
.include "components/collision.asm"
.include "components/enemy_cmp.asm"
.include "entities/entity.asm"
.include "entities/projectile.asm"
.include "entities/enemy.asm"

.include "testbed_config.asm"

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

    ; setup initial player position
    lda #$80
    sta player_pos_x

    lda #$80
    sta player_pos_y

    jsr initialize_test

    lda #$00
    sta update_animations

    ldx #$ff

;
; Here we setup the PPU for drawing by writing apropriate memory-mapped
; registers and specific memory locations.
;
; IMPORTANT! Writes to the PPU RAM afterwards should occur only during VBlank!
;
ppusetup:
    ; First set the universal background color
    lda #>VRAM_BGCOLOR
    sta PPUADDR
    lda #<VRAM_BGCOLOR
    sta PPUADDR

    lda #BG_COLOR
    sta PPUDATA

    ; write the background palette color indices
    lda #>background_palettes   ; PALETTE_ADDR_HI
    sta $00,X
    dex
    lda #<background_palettes   ; PALETTE_ADDR_LO
    sta $00,X
    dex
    lda #<VRAM_BGR_PAL0         ; VRAM_PAL_ADDR_LO
    sta $00,X
    dex
    lda #>VRAM_BGR_PAL0         ; VRAM_PAL_ADDR_HI
    sta $00,X
    dex
    lda #$10                    ; NUM_COLORS
    sta $00,X
    dex
    jsr load_color_palettes

    ; write the sprite palette color indices
    lda #>sprite_palettes       ; PALETTE_ADDR_HI
    sta $00,X
    dex
    lda #<sprite_palettes       ; PALETTE_ADDR_LO
    sta $00,X
    dex
    lda #<VRAM_SPR_PAL0         ; VRAM_PAL_ADDR_LO
    sta $00,X
    dex
    lda #>VRAM_SPR_PAL0         ; VRAM_PAL_ADDR_HI
    sta $00,X
    dex
    lda #$10                    ; NUM_COLORS
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

    ; Ready to go, enable VBlank NMI, all subsequent writes should take place
    ; during VBlank, inside NMI handler.
    lda #$90
	sta PPUCTRL

main:
    ;
    ; Display the message on screen using sprites representing ASCII symbols
    ;
    ldx #$00 ; character index
    ldy #$00 ; byte offset

    jsr execute_test

return_to_main:
    
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

    lda #$01
    sta update_flags

    inc update_animations

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

    ; set scroll, what pixel of the NT should be on the left top of the screen
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
; handle input
;
handle_input:
    ; first latch buttons to be able to poll input
    lda #$01            ; fill input from buttons currently held
    sta JOYPAD1 
    lda #$00            ; return to serial mode wait for bits to be read out
    sta JOYPAD1

    ldx #$00
    ; we don't process those yet, need to be executed in correct order
    ; check if magic flag is set for this button and store direction indicator 


    lda JOYPAD1         ; Player 1 - A
    and #$01
    beq :+
    txa
    ora #INCREASE_SPEED
    tax

:   lda JOYPAD1         ; Player 1 - B
    and #$01
    beq :+
    txa
    ora #DECREASE_SPEED
    tax

:   lda JOYPAD1         ; Player 1 - Select
    lda JOYPAD1         ; Player 1 - Start

    lda JOYPAD1         ; Player 1 - Up
    and #$01
    beq :+
    txa
    ora #MOVE_UP
    tax

 :  lda JOYPAD1         ; Player 1 - Down
    and #$01
    beq :+
    txa
    ora #MOVE_DOWN
    tax

:   lda JOYPAD1         ; Player 1 - Left
    and #$01
    beq :+
    txa
    ora #MOVE_LEFT
    tax

:   lda JOYPAD1         ; Player 1 - Right
    and #$01
    beq :+
    txa
    ora #MOVE_RIGHT
    tax

:   txa
    sta player_direction
    rts

;
; Interrupt handler vectors (pointers).
; Three 16 bit addresses to, respectively, the NMI, RESET and IRQ handlers.
;
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
