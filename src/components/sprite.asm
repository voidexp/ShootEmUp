.include "constants.asm"
.include "globals.asm"
.include "macros.asm"
.include "nes.asm"

.export init_sprites
.export create_sprite
.export draw_sprites

;
; Sprite instance.
;
.struct Sprite
    pos     .word   ; X,Y coordinates
    anim    .addr   ; animation descriptor
    frame   .byte   ; current animation frame index
    elapsed .byte   ; number of frames elapsed since last frame advance
.endstruct


;
; Animation descriptor (read-only).
;
.struct Animation
    length  .byte   ; length in frames
    speed   .byte   ; playback speed
    tile0   .byte   ; starting tile ID
    attr    .byte   ; attribute set
    size    .byte   ; frame size in tiles
.endstruct


.segment "BSS"
; array of sprite components
sprites: .res (.sizeof(Sprite) * 8)
sprites_end:


.rodata
;
; Table with pre-multiplied tile offsets in pixels
;
tile_offsets: .byte 0, PIXELS_PER_TILE, PIXELS_PER_TILE * 2, PIXELS_PER_TILE * 3


.code
;
; Inititalize sprites subsystem.
;
.proc init_sprites
    ; FIXME: is this really necessary?
    rts
.endproc


;
; Create a sprite.
;
; Parameters:
;   var_1       - X coord
;   var_2       - Y coord
;   address_1   - animation descriptor address
;
; Returns:
;   address_2   - address of created sprite
;
; Allocates an entry in the sprites array, initializes it and returns its
; address.
;
.proc create_sprite

.mac find_empty
            ldy #Sprite::anim + 1   ; offset to animation address hi byte
            lda (address_2),y       ; load hi part, if null, Z is set and iteration stops
.endmac

            ; search for an unused sprite entry, address_2 used as iterator
            lda #<sprites
            sta address_2
            lda #>sprites
            sta address_2 + 1
            find_ptr address_2, sprites_end, .sizeof(Sprite), find_empty

            ldy #Sprite::pos        ; set Y index to 'pos' field offset
            lda var_1               ; load X coord
            sta (address_2),y       ; save X coord

            iny                     ; set Y index to 'pos' field's Y coord offset
            lda var_2               ; load Y coord
            sta (address_2),y       ; save Y coord

            ldy #Sprite::anim       ; set Y index to 'anim' field offset
            lda address_1           ; sprite anim address lo
            sta (address_2),y       ; save lo

            iny                     ; advance Y index to hi address part
            lda address_1 + 1       ; sprite address hi
            sta (address_2),y       ; save hi

            ldy #Sprite::frame      ; set Y index to 'frame' field offset
            lda #$00                ; new sprites always start animation from beginning
            sta (address_2),y       ; save frame index

            ldy #Sprite::elapsed    ; offset to 'elapsed' field
            sta (address_2),y       ; zero it out

            rts
.endproc

;
; ARGS:
; y                      - oam offset
;
; RETURN:
; y                      - oam offset
;
.proc draw_sprites
            tya                     ; OAM offset to A
            tax                     ; OAM offset to X

.mac iter_sprite
            ldy #Sprite::pos        ; load X,Y coords into var_5 and var_6
            lda (address_1),y
            sta var_5
            iny
            lda (address_1),y
            sta var_6

            ldy #Sprite::anim + 1   ; load animation addr hi offset to Y
            lda (address_1),y       ; load hi addr part
            beq @skip               ; skip this sprite if hi addr part is null
            sta address_3 + 1       ; store to address_3 hi byte
            dey                     ; lo offset
            lda (address_1),y       ; load lo addr part
            sta address_3           ; store to address_3 lo byte

            ;
            ; Advance the animation frame if enough frames passed since last
            ; update.
            ;
            ldy #Sprite::frame
            lda (address_1),y       ; load current frame value
            sta var_4               ; copy to var_4, used both as temporary var and argument later

            ldy #Sprite::elapsed
            lda (address_1),y       ; load elapsed frames counter
            clc
            adc #1                  ; increment it; use addition since there's no indexed inc
            sta (address_1),y       ; save back to 'elapsed' field
            ldy #Animation::speed
            cmp (address_3),y       ; compare elapsed counter with reference speed value
            bne :++                 ; if not reached, skip frame advance, var_4 left as-is
            lda #0                  ; else, reset elapsed frames counter
            ldy #Sprite::elapsed
            sta (address_1),y       ; save the new frame counter back to 'elapsed' field
            inc var_4               ; advance the frame index
            lda var_4
            ldy #Animation::length
            cmp (address_3),y       ; compare it with animation length in the descriptor
            bne :+
            lda #0                  ; reset if last frame is reached
:           ldy #Sprite::frame
            sta (address_1),y       ; save the new frame index back to 'frame' field
            sta var_4

:           ldy #Animation::size    ; load the sprite size
            lda (address_3),y
            sta var_2               ; copy it to var_2

            mult_variables var_4, var_2, temp_1; frame * size = offset to first tile

            ldy #Animation::tile0   ; load the ID of the first tile
            lda (address_3),y
            clc
            adc temp_1              ; add the offset to it
            sta var_7               ; store the result to var_7

            ldy #Animation::attr    ; load attribute value to var_8
            lda (address_3),y
            sta var_8

            jsr draw_frame
@skip:
.endmac

            ; execute the code above for each sprite using address_1 as iterator
            lda #<sprites
            sta address_1
            lda #>sprites
            sta address_1 + 1
            iter_ptr address_1, sprites_end, .sizeof(Sprite), iter_sprite

            txa                     ; OAM offset to A
            tay                     ; OAM offset to Y
            rts
.endproc

;
; Draw an animation frame.
;
; Parameters:
;   x       - current OAM offset
;   var_2   - frame size
;   var_5   - X position
;   var_6   - Y position
;   var_7   - ID of the first tile
;   var_8   - attribute
;
; Returns:
;   x       - updated OAM offset
;
; Based on frame geometry (1x1, 2x2, 3x3, etc), calculates the positions and
; draws all the tiles that make up the frame.
;
.proc draw_frame
            dec var_2               ; subtract 1 from size
            lda var_2               ; var_2 for height (rows)
            sta var_1               ; var_1 for width (columns)
            pha                     ; push it to stack ... we need it later again

            ; compute the tile ID offset for the lowest row:
            ; offset = (size - 1) * 16
            asl
            asl
            asl
            asl
            sta var_3               ; var_3 for current offset

            ; draw all the tiles, starting from the right-most one of the lowest
            ; row and going left and up
@draw_row:  jsr draw_tile           ; draw a tile
            lda var_1               ; check if there are more on this row
            beq :+                  ; if the row is done, advance to next (upper) one
            dec var_1               ; else, advance one tile to the left
            jmp @draw_row           ; repeat
:           lda var_2               ; check remaining rows
            beq @epic_end           ; if we're done, bail out
            pla                     ; get original row width from the stack
            sta var_1               ; reset the counter of tiles in a row
            pha                     ; save it again on the stack
            dec var_2               ; decrement the rows counter
            lda var_3               ; load the tile ID offset
            sec                     ; subtract the row pitch from it
            sbc #16
            sta var_3               ; and save back
            jmp @draw_row           ; draw another row

@epic_end:  pla                     ; restore the stack
            rts
.endproc


;
; Draw a single sprite tile.
;
; Parameters:
;   x       - OAM offset
;   var_1   - X offset
;   var_2   - Y offset
;   var_3   - row tile ID offset
;   var_5   - X position
;   var_6   - Y position
;   var_7   - starting tile ID
;   var_8   - attributes
; Returns:
;   x       - updated OAM offset
;
; TODO: move offset calculation to draw_frame?
;
.proc draw_tile
            ; OAM entry structure reminder:
            ;   byte 0: Y position of sprite's top side
            ;   byte 1: tile index
            ;   byte 2: attributes
            ;   byte 3: X position of sprite's left side

            lda var_6               ; load Y position
            ldy var_2               ; index in the premultiplied sizes table
            clc
            adc tile_offsets,y      ; add the vertical offset in pixels to it
            sta oam,x               ; write to OAM Y coord byte

            lda var_7               ; load tile id
            clc
            adc var_1               ; add column offset
            adc var_3               ; add row offset
            inx
            sta oam,x               ; write to OAM tile id byte

            lda var_8               ; load attribute id
            inx
            sta oam,x               ; write to OAM attributes byte

            lda var_5               ; load X position
            ldy var_1               ; index in the premultiplied sizes table
            clc
            adc tile_offsets,y      ; add horizontal offset in pixels to it
            inx
            sta oam,x               ; write to OAM X coord byte

            inx                     ; advance to the beginning of next OAM entry

            rts
.endproc
