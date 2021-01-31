.include "nes.asm"
.include "globals.asm"

.import copy_to_vram

BGCOLOR =  $0d          ; Overall background color index
BGR_PAL0 = $103020      ; Background 0 tiles palette indices
PLCOLOR0 =  $022232     ; Player palette color indices
PLCOLOR1 =  $162637      ; Player palette color indices


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
    update_flags:    .res 1 ; flags what to update (0000 000 UPDATE_POSITIONS)
    draw_flags:  	    .res 1 ; flags what to draw in the next frame (0000 000 DRAW_FLAME)

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
    lda #$74
    sta player_pos_x

    lda #$74
    sta player_pos_y

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

    ; write the color indices
    lda #(PLCOLOR0 >> 16)
    sta PPUDATA
    lda #(PLCOLOR0 >> 8) & $ff
    sta PPUDATA
    lda #(PLCOLOR0 & $ff)
    sta PPUDATA

    ;
    ; Set sprite-1 palette
    ;
    ; set PPUADDR destination address to Sprite Palette 0 ($3F11)
    lda #>VRAM_SPR_PAL1
    sta PPUADDR
    lda #<VRAM_SPR_PAL1
    sta PPUADDR

    ; write the color indices
    lda #(PLCOLOR1 >> 16)
    sta PPUDATA
    lda #(PLCOLOR1 >> 8) & $ff
    sta PPUDATA
    lda #(PLCOLOR1 & $ff)
    sta PPUDATA

    ;
    ; Clear PPU status and scroll registers
    ;
    bit PPUSTAT
    lda #$00
    sta PPUSCRL
    sta PPUSCRL

    ; clear player direction
    sta player_direction

    lda #$01
    sta player_speed

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

    jsr handle_input ; process input and reposition the ship

    ; 
    ; update position of player
    ; check if one of the position bits is set if so, update the position of the player
update_player_position:
    ; check how often to increase the player position, depending on the speed
    lda #%00000001
    cmp update_flags  ; check if the last frame was drawn then update the position for the next one
    bne draw_player

    ; reset draw flags, set them one by one for the elements
    lda #$00
    sta draw_flags  

    lda player_speed  ; check if the player is currently in high speed mode
    cmp #$04
    bmi increase_speed

    inc draw_flags  ; set the draw flag for the flame 
increase_speed:
    lda #INCREASE_SPEED
    bit player_direction
    beq decrease_speed

    ; cap the max speed at 8px
    lda player_speed
    cmp #$08            
    bpl decrease_speed
    inc player_speed
decrease_speed:
    lda #DECREASE_SPEED
    bit player_direction
    beq move_up

    ; cap the min speed at 1px
    lda player_speed
    cmp #$02
    bmi move_up
    dec player_speed
move_up:
    lda #MOVE_UP
    bit player_direction
    beq move_down
    ; move up
    lda player_pos_y
    sec 
    sbc player_speed
    sta player_pos_y
move_down:
    lda #MOVE_DOWN
    bit player_direction
    beq move_left 
    ; move down
    lda player_pos_y
    clc 
    adc player_speed
    sta player_pos_y
move_left:
    lda #MOVE_LEFT
    bit player_direction
    beq move_right
    ; move left
    lda player_pos_x
    sec
    sbc player_speed
    sta player_pos_x
move_right:
    lda #MOVE_RIGHT
    bit player_direction
    beq end_of_player_move
    ; move right
    lda player_pos_x
    clc
    adc player_speed
    sta player_pos_x

end_of_player_move:
    ; reset frame counter and player direction and update the position in the next second
    ; so that the next time 
    lda #$00
    sta player_direction
    sta update_flags

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
    lda player_pos_y
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
    lda player_pos_x
    sta oam,Y
    iny

    ;
    ; sprite $01
    ;
    ; Y coord
    txa
    lda player_pos_y
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
    lda player_pos_x 
    clc
    adc #$08
    sta oam,Y
    iny

    ;
    ; sprite $10
    ;
    ; Y coord
    txa
    lda player_pos_y
    clc
    adc #$08
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
    lda player_pos_x
    sta oam,Y
    iny

	;
    ; sprite $11
    ;
    ; Y coord
    txa
    lda player_pos_y
    adc #$08
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
    lda player_pos_x
    clc
    adc #$08
    sta oam,Y
    iny
    
draw_flame:
    lda #%00000001 
    bit draw_flags
    beq return_to_main

    lda #$00
    sta $0e

	;
    ; sprite $03
    ;
    ; Y coord
    lda player_pos_y
    adc #$0f
    sta oam,Y
    iny
    ; sprite id
    lda #$03
    sta oam,Y
    iny
    ; sprite attrs
    lda #$01
    sta oam,Y
    iny
    ; X coord
    lda player_pos_x
    adc #$04
    sta oam,Y
    iny
    
return_to_main:
    lda #$ff
    sta $0e
    
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
    lda #$01          ; fill input from buttons currently held
    sta JOYPAD1 
    lda #$00          ; return to serial mode wait for bits to be read out
    sta JOYPAD1

    ; we don't process those yet, need to be executed in correct order
    lda JOYPAD1       ; Player 1 - A
    and #%00000001
    bne handle_increase_speed


    lda JOYPAD1       ; Player 1 - B
    and #%00000001
    bne handle_decrease_speed

    lda JOYPAD1       ; Player 1 - Select
    lda JOYPAD1       ; Player 1 - Start

    lda JOYPAD1       ; Player 1 - Up
    and #%00000001
    bne handle_up
        
    lda JOYPAD1       ; Player 1 - Down
    and #%00000001
    bne handle_down
        
    lda JOYPAD1       ; Player 1 - Left
    and #%00000001
    bne handle_left

    lda JOYPAD1       ; Player 1 - Right
    and #%00000001
    bne handle_right
    rts 

abort:
    rts

handle_increase_speed:
    ; check if the speed increase is already set otherwise return
    lda #INCREASE_SPEED
    bit player_direction
    bne skip_moving

    lda player_direction
    clc
    adc #INCREASE_SPEED 
    sta player_direction
    rts

handle_decrease_speed:
    lda #DECREASE_SPEED
    bit player_direction
    bne skip_moving

    lda player_direction
    clc
    adc #DECREASE_SPEED 
    sta player_direction
    rts

handle_right:
    ; check if the direction is already set otherwise return
    lda #MOVE_RIGHT
    bit player_direction
    bne skip_moving

    lda player_direction
    clc
    adc #MOVE_RIGHT 
    sta player_direction
    rts

handle_left:
    ; check if the direction is already set otherwise return
    lda #MOVE_LEFT
    bit player_direction
    bne skip_moving

    lda player_direction
    clc
    adc #MOVE_LEFT 
    sta player_direction
    rts

handle_up:
    ; check if the direction is already set otherwise return
    lda #MOVE_UP
    bit player_direction
    bne skip_moving

    lda player_direction
    adc #MOVE_UP
    sta player_direction
    rts

handle_down:
    ; check if the direction is already set otherwise return
    lda #MOVE_DOWN
    bit player_direction
    bne skip_moving

    lda player_direction
    clc
    adc #MOVE_DOWN 
    sta player_direction
    rts

skip_moving:
    rts

;
; Interrupt handler vectors (pointers).
; Three 16 bit addresses to, respectively, the NMI, RESET and IRQ handlers.
;
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
