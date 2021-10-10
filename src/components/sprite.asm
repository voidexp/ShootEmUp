.include "globals.asm"
.include "macros.asm"
.include "nes.asm"
.include "structs.asm"

.export create_sprite
.export destroy_sprite
.export destroy_sprites
.export draw_sprites


.rodata
;
; Table with pre-multiplied tile offsets in pixels
;
tile_offsets: .byte 0, 8, 16, 24


.code
;
; Create a sprite.
;
; Parameters:
;   var1    - X coord
;   var2    - Y coord
;   ptr1    - animation descriptor address
;
; Returns:
;   ptr2    - address of created sprite
;
; Allocates an entry in the sprites array, initializes it and returns its
; address.
;
.proc create_sprite

.mac find_empty
            ldy #Sprite::anim + 1   ; offset to animation address hi byte
            lda (ptr2),y            ; load hi part, if null, Z is set and iteration stops
.endmac

            ; search for an unused sprite entry, ptr2 used as iterator
            lda #<sprites
            sta ptr2
            lda #>sprites
            sta ptr2 + 1
            find_ptr ptr2, sprites_end, .sizeof(Sprite), find_empty

            ldy #Sprite::pos        ; set Y index to 'pos' field offset
            lda var1                ; load X coord
            sta (ptr2),y            ; save X coord

            iny                     ; set Y index to 'pos' field's Y coord offset
            lda var2                ; load Y coord
            sta (ptr2),y            ; save Y coord

            ldy #Sprite::anim       ; set Y index to 'anim' field offset
            lda ptr1                ; sprite anim address lo
            sta (ptr2),y            ; save lo

            iny                     ; advance Y index to hi address part
            lda ptr1 + 1            ; sprite address hi
            sta (ptr2),y            ; save hi

            ldy #Sprite::frame      ; set Y index to 'frame' field offset
            lda #$00                ; new sprites always start animation from beginning
            sta (ptr2),y            ; save frame index

            ldy #Sprite::elapsed    ; offset to 'elapsed' field
            sta (ptr2),y            ; zero it out

            rts
.endproc


;
; Destroy a sprite.
;
; Arguments:
;   ptr1    - address of the sprite to destroy
;
.proc destroy_sprite
            fill_mem ptr1, .sizeof(Sprite), #0
            rts
.endproc


;
; Destroy all sprites.
;
.proc destroy_sprites
.mac cleanup
            fill_mem tmp1, .sizeof(Sprite), #0
.endmac
            lda #<sprites
            sta tmp1
            lda #>sprites
            sta tmp2
            iter_ptr tmp1, sprites_end, .sizeof(Sprite), cleanup

            rts
.endproc


;
; Draw currently active sprites to shadow OAM, which will be copied over next
; update.
;
.proc draw_sprites
            ;
            ; Clear shadow OAM
            ;
            lda #0
            tax
@clr_oam:   sta oam,x
            inx
            bne @clr_oam

.mac iter_sprite
            ldy #Sprite::pos        ; load X,Y coords into var5 and var6
            lda (ptr1),y
            sta var5
            iny
            lda (ptr1),y
            sta var6

            ldy #Sprite::anim + 1   ; load animation addr hi offset to Y
            lda (ptr1),y            ; load hi addr part
            beq @skip               ; skip this sprite if hi addr part is null
            sta ptr3 + 1            ; store to ptr3 hi byte
            dey                     ; lo offset
            lda (ptr1),y            ; load lo addr part
            sta ptr3                ; store to ptr3 lo byte

            ;
            ; Advance the animation frame if enough frames passed since last
            ; update.
            ;
            ldy #Sprite::frame
            lda (ptr1),y            ; load current frame value
            sta var4                ; copy to var4, used both as temporary var and argument later

            ldy #Sprite::elapsed
            lda (ptr1),y            ; load elapsed frames counter
            clc
            adc #1                  ; increment it; use addition since there's no indexed inc
            sta (ptr1),y            ; save back to 'elapsed' field
            ldy #Animation::speed
            cmp (ptr3),y            ; compare elapsed counter with reference speed value
            bne :++                 ; if not reached, skip frame advance, var4 left as-is
            lda #0                  ; else, reset elapsed frames counter
            ldy #Sprite::elapsed
            sta (ptr1),y            ; save the new frame counter back to 'elapsed' field
            inc var4                ; advance the frame index
            lda var4
            ldy #Animation::length
            cmp (ptr3),y            ; compare it with animation length in the descriptor
            bne :+
            lda #0                  ; reset if last frame is reached
:           ldy #Sprite::frame
            sta (ptr1),y            ; save the new frame index back to 'frame' field
            sta var4

:           ldy #Animation::size    ; load the sprite size
            lda (ptr3),y
            sta var2                ; copy it to var2

            mult_variables var4, var2, tmp1; frame * size = offset to first tile

            ldy #Animation::tile0   ; load the ID of the first tile
            lda (ptr3),y
            clc
            adc tmp1                ; add the offset to it
            sta var7                ; store the result to var7

            ldy #Animation::attr    ; load attribute value to var8
            lda (ptr3),y
            sta var8

            jsr draw_frame
@skip:
.endmac

            ; execute the code above for each sprite using ptr1 as iterator
            lda #<sprites
            sta ptr1
            lda #>sprites
            sta ptr1 + 1
            iter_ptr ptr1, sprites_end, .sizeof(Sprite), iter_sprite

            rts
.endproc

;
; Draw an animation frame.
;
; Parameters:
;   x       - current OAM offset
;   var2   - frame size
;   var5   - X position
;   var6   - Y position
;   var7   - ID of the first tile
;   var8   - attribute
;
; Returns:
;   x       - updated OAM offset
;
; Based on frame geometry (1x1, 2x2, 3x3, etc), calculates the positions and
; draws all the tiles that make up the frame.
;
.proc draw_frame
            dec var2                ; subtract 1 from size
            lda var2                ; var2 for height (rows)
            sta var1                ; var1 for width (columns)
            pha                     ; push it to stack ... we need it later again

            ; compute the tile ID offset for the lowest row:
            ; offset = (size - 1) * 16
            asl
            asl
            asl
            asl
            sta var3                ; var3 for current offset

            ; draw all the tiles, starting from the right-most one of the lowest
            ; row and going left and up
@draw_row:  jsr draw_tile           ; draw a tile
            lda var1                ; check if there are more on this row
            beq :+                  ; if the row is done, advance to next (upper) one
            dec var1                ; else, advance one tile to the left
            jmp @draw_row           ; repeat
:           lda var2                ; check remaining rows
            beq @epic_end           ; if we're done, bail out
            pla                     ; get original row width from the stack
            sta var1                ; reset the counter of tiles in a row
            pha                     ; save it again on the stack
            dec var2                ; decrement the rows counter
            lda var3                ; load the tile ID offset
            sec                     ; subtract the row pitch from it
            sbc #16
            sta var3                ; and save back
            jmp @draw_row           ; draw another row

@epic_end:  pla                     ; restore the stack
            rts
.endproc


;
; Draw a single sprite tile.
;
; Parameters:
;   x       - OAM offset
;   var1   - X offset
;   var2   - Y offset
;   var3   - row tile ID offset
;   var5   - X position
;   var6   - Y position
;   var7   - starting tile ID
;   var8   - attributes
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

            lda var6                ; load Y position
            ldy var2                ; index in the premultiplied sizes table
            clc
            adc tile_offsets,y      ; add the vertical offset in pixels to it
            sta oam,x               ; write to OAM Y coord byte

            lda var7                ; load tile id
            clc
            adc var1                ; add column offset
            adc var3                ; add row offset
            inx
            sta oam,x               ; write to OAM tile id byte

            lda var8                ; load attribute id
            inx
            sta oam,x               ; write to OAM attributes byte

            lda var5                ; load X position
            ldy var1                ; index in the premultiplied sizes table
            clc
            adc tile_offsets,y      ; add horizontal offset in pixels to it
            inx
            sta oam,x               ; write to OAM X coord byte

            inx                     ; advance to the beginning of next OAM entry

            rts
.endproc
