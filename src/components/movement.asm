.include "constants.asm"
.include "globals.asm"
.include "macros.asm"

.export create_movement_component
.export init_movement_components
.export update_movement_components

; movement component
; size -> 5 byte

.rodata
MOVE_COMP_SIZE = 5

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; movement_component:
;    .addr owner                     ; entity -> contains x and y position
;    .byte speed
;    .byte dirX, dirY
; movement rule
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; update all movements

; container for 25 movement components
; addresses or data? -> addresses

.segment "BSS"
movement_component_container: .res 150

num_movement_components: .res 1


.code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_movement_components:
    lda #$00
    sta num_movement_components
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; create movement components
; ARGS:
;   var1               - xPosition
;   var2               - yPosition
;   var3               - xDir
;   var4               - yDir, now one byte will be reduced
;   var5               - speed

;   ptr1           - owner
;
; RETURN:
;   ptr2           - address of movement_component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_movement_component
    ; calculate offset in current component buffer
    mult_with_constant num_movement_components, #MOVE_COMP_SIZE, var5

    calc_address_with_offset movement_component_container, var5, ptr2 ; use ptr2 as ptr3 is return address

    ldy #$00                                ; owner lo
    lda ptr1
    sta (ptr2), y

    iny
    lda ptr1 + 1                       ; owner hi
    sta (ptr2), y
    iny

    lda var5                               ; speed
    sta (ptr2), y
    iny

    lda var3                               ; dirX
    sta (ptr2), y
    iny

    lda var4                               ; dirY
    sta (ptr2), y
    iny

    inc num_movement_components
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; update movement components
; ARGS:
;
; RETURN:
;   ptr1             - updated movement component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_movement_components
    ; calculate max value and store it in var1
    mult_with_constant num_movement_components, #MOVE_COMP_SIZE, var1

    lda num_movement_components
    sta var1

    lda #<movement_component_container
    sta ptr1

    lda #>movement_component_container
    sta ptr1 + 1

    ldy #$00

@update_mov_comp:
    lda var1
    cmp #$00
    bne :+
    rts                                     ; return if no components are left
:   lda (ptr1), y                      ; Get entity address lo byte
    sta ptr2
    iny

    lda (ptr1), y                      ; Get entity address hi byte
    sta ptr2 + 1
    iny

    tya                                     ; push y to stack
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (ptr2), y
    sta var2
    iny

    lda (ptr2), y
    sta var3
    iny
    iny                                     ; jump over components

    lda (ptr2), Y                      ; check if movement component is active
    sta var5

    pla                                     ; get y offset from stack again
    tay

    lda #MOVEMENT_CMP
    bit var5
    bne :+                                  ; jump to next vomponent
    iny
    iny
    iny
    dec var1
    jmp @update_mov_comp

:   lda (ptr1), y
    sta var4                               ; speed
    iny

    lda (ptr1), Y
    sta var5                               ; dirX
    iny

    lda (ptr1), Y
    sta var6                               ; dirY
    iny

    tya
    pha

    ; mult_variables var5, var4, var7      ; calculate offset in x direction
    ldx #$00
    ldy #$00
    lda var2
    sta var8
    clc
    adc var5
    sta (ptr2), y                      ; store new x pos
    sta var7

    lda var5
    sta var9

    iny
    lda var3                               ; add speed to previous position
    sta var8
    clc
    adc var6
    sta var7

    lda var6
    sta var9
    ldx #$00
    jsr check_for_overflow

    cpx #$01
    bcc :+
    lda var3
    sta var7
 :  lda var7
    sta (ptr2), y                     ; store new y pos

    pla
    tay

    ; if outside of screen stop the projectile by setting the direction to zero
    cpx #$01
    bcc :+
    dey
    lda var9
    clc
    eor #$ff
    adc #$01
    sta (ptr1), Y                      ; overwrite yDir
    dey
    lda #$00
    sta (ptr1), Y                      ; overwrite xDir
    iny
    iny

:   dec var1
    jmp @update_mov_comp
.endproc


; var7                 : new value
; var8                 : old value
; var9                 : dif
; var10                : result
check_for_overflow:
    lda var9
    bmi @check_negative_val

    lda var7                               ; new value is bigger then old value -> carry set .. return
    cmp var8
    bcs @return
    inx

@check_negative_val:
    lda var8   ; direction is negative .. old value needs to be bigger than new value
    cmp var7  ;var8
    bcs @return
    inx
@return:
    rts
