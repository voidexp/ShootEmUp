.include "nes.asm"
.include "constants.asm"
.include "macros.asm"

.import draw_end_text
.import draw_sprite_components
.import update_sprite_components
.import enemy_cmp_process_cd_results
.import update_collision_components
.import update_movement_components
.import update_actor_components
.import copy_to_vram
.import sprite_palettes
.import load_color_palettes
.import background_palettes
.import num_enemy_components
.import spawn_spacetopus
.import create_player
.import create_flame
.import create_player_projectile
.import initialize_entities
.import num_rainbows


; TODO: move this to sprite.asm
ANIMATION_SPEED = 8

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


; Zero-page RAM.
;
.zeropage
    frame_counter:      .res 1  ; current frame, wraps at $ff

    ; moving player
    player_speed:       .res 1  ; current player speed
    player_direction:   .res 1  ; current direction bit set  (0000 LEFT DOWN RIGHT UP)
    player_entity_adr:  .res 2  ; Player entity address

    ; scroll
    scroll_y:           .res 1
    scroll_x:           .res 1

    ; draw flags
    update_flags:       .res 1  ; flags what to update (0000 000 UPDATE_POSITIONS)
    draw_flags:         .res 1  ; flags what to draw in the next frame (0000 000 DRAW_FLAME)
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

.exportzp temp_1, temp_2, temp_3, temp_4, temp_5, temp_6
.exportzp var_1, var_2, var_3, var_4, var_5, var_6, var_7, var_8, var_9, var_10
.exportzp address_1, address_2, address_3, address_4, address_5, address_6, address_7, address_8, address_9, address_10
.exportzp update_flags, draw_flags
.exportzp kill_count, num_enemies_alive

;
; PPU Object Attribute Memory - shadow RAM which holds rendering attributes
; of up to 64 sprites.
;
.segment "OAM"
    oam: .res 256

.export oam

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
    ; initialize settings
    lda #$00
    sta update_animations

    lda #$00
    sta kill_count
    sta shoot_cooldown
    sta num_rainbows

    jsr initialize_entities
    jsr create_player_projectile

    ; create flame entity
    lda #$84                                ; x-Pos
    sta var_1

    lda #$bc                                ; y-Pos
    sta var_2

    jsr create_flame

    ; store flame address in address 2 so it can be correctly linked to the player actor component
    lda address_1
    sta address_4

    lda address_1 + 1
    sta address_4 + 1

    lda #$80
    sta var_1

    lda #$b0
    sta var_2

    lda #$00
    sta var_3
    lda #$00
    sta var_4

    jsr create_player

    lda address_1
    sta player_entity_adr

    iny
    lda address_1 + 1
    sta player_entity_adr + 1

    ; jsr spawn_squady
    jsr spawn_spacetopus

    lda num_enemy_components
    sta num_enemies_alive

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

    ; jsr handle_input ; process input and reposition the ship
    ;
    ; update position of player
    ; check if one of the position bits is set if so, update the position of the player
update_player_position:
    ; check how often to increase the player position, depending on the speed
    lda update_flags
    cmp #$01  ; check if the last frame was drawn then update the position for the next one
    bcc update_anim_components

    jsr update_actor_components             ; process_controller_input

    ; UPDATE COMPONENTS
    jsr update_movement_components
    jsr update_collision_components

    jsr enemy_cmp_process_cd_results


update_anim_components:
    lda update_animations
    cmp #ANIMATION_SPEED
    bcc start_rendering
    jsr update_sprite_components
    lda #$00
    sta update_animations

start_rendering:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; START RENDERING SET OAM OFFSET TO 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldy #$00

draw_kill_count:

    lda num_enemies_alive
    cmp #$02
    bcc check_game_state
    lda #$0a        ; sprite xpos
    sta var_2
    lda kill_count
    sta var_1
    cmp #$0a

    bcc :+

    lda var_1
    sec
    sbc #$0a
    sta var_1

    ; move xpos for second tile
    lda var_2
    clc
    adc #$08
    sta var_2

    lda #$0c
    sta oam,Y
    iny
    ; sprite id
    lda #$31
    sta oam,Y
    iny
    ; sprite attrs
    lda #$01
    sta oam,Y
    iny
    ; X coord
    lda #$0a
    sta oam,Y
    iny

:   lda #$0c
    sta oam,Y
    iny
    ; sprite id
    lda #$30
    clc
    adc var_1
    sta oam,Y
    iny
    ; sprite attrs
    lda #$01
    sta oam,Y
    iny
    ; X coord
    lda var_2
    sta oam,Y
    iny

components:
    jsr draw_sprite_components
    jmp return_to_main
check_game_state:
    lda num_enemies_alive
    cmp #$02
    bcs return_to_main

    tya
    pha
    ; jsr create_rainbow
    pla
    tay
    jsr draw_end_text



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

    inc update_flags

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
    rts

;
; Interrupt handler vectors (pointers).
; Three 16 bit addresses to, respectively, the NMI, RESET and IRQ handlers.
;
.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
