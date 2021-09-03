.include "globals.asm"
.include "macros.asm"
.include "constants.asm"


.import disable_all_entity_components

.export create_collision_component
.export init_collision_components
.export update_collision_components

; list of all collision components
.rodata

COLL_COMP_SIZE = 8


.segment "BSS"
collision_component_container:  .res 120

num_collision_components:       .res 1

collision_results:              .res 20
num_collision_results:          .res 1

.export collision_results, num_collision_results

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
.proc init_collision_components
    lda #$00
    sta num_collision_components
    sta num_collision_results
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CREATES COLLISION COMPONENT
; Args:
;   var1               - collision mask
;   var2               - collision layer
;   var3               - width
;   var4               - height

;   ptr1           - owner
;
; Result:
;   ptr2           - address of the coll component
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;    .addr owner
;    .byte collision_mask
;    .byte collision_layer
;    .byte xMin offset
;    .byte xMax offset
;    .byte yMin offset
;    .byte yMax offset
;
;   xMin, yMin     _    xMax, yMin
;   |              |             |
;   |             pos            |
;   |              |             |
;   xMin, yMax     _    xMax, yMax
;
; updates collision components
; -> stores collisions
; -> notifies components
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc create_collision_component
    ; calculate offset in current component buffer
    mult_with_constant num_collision_components, #COLL_COMP_SIZE, var5

    calc_address_with_offset collision_component_container, var5, ptr2 ; use ptr2 as ptr3 is return address

    ldy #$00                                ; owner lo
    lda ptr1
    sta (ptr2), y

    iny
    lda ptr1 + 1                       ; owner hi
    sta (ptr2), y
    iny

    lda var1                               ; collision mask
    sta (ptr2), y
    iny

    lda var2                               ; collision layer
    sta (ptr2), y
    iny

    mult_with_constant var3, #4, var5     ; multiply by eight -> size in pixel
    lda var5                               ; xMin
    clc
    eor #$ff
    adc #$01
    sta (ptr2), y
    iny

    lda var5                               ; xMax
    sta (ptr2), y
    iny

    mult_with_constant var4, #4, var5     ; multiply by eight -> size in pixel
    lda var5                               ; yMin
    clc
    eor #$ff
    adc #$01
    sta (ptr2), y
    iny

    lda var5                               ; yMax
    sta (ptr2), y
    iny

    inc num_collision_components
    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PERFORM CD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc update_collision_components
    ; reset results
    lda #$00
    sta num_collision_results

    jsr detect_collisions

    lda num_collision_results
    cmp #$00
    bne :+
    ; no collision found
    rts
:
    ldy #$00

    lda #<collision_results
    sta ptr2

    lda #>collision_results
    sta ptr2 + 1
    ; process collision

    lda (ptr2), Y                      ; Get first entity address lo byte
    sta ptr3
    iny

    lda (ptr2), y                      ; Get first entity address hi byte
    sta ptr3 + 1
    iny

    lda (ptr2), Y                      ; get address of second entity
    sta ptr4
    iny

    lda (ptr2), Y
    sta ptr4 + 1
    iny

    lda ptr3
    sta ptr1

    lda ptr3 + 1
    sta ptr1 + 1
    jsr disable_all_entity_components

    lda ptr4
    sta ptr1

    lda ptr4 + 1
    sta ptr1 + 1
    jsr disable_all_entity_components

    rts
.endproc


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; actual CD
; instead of check if there IS a collision, check if there ISN'T
; * sprite2.x > sprite1.x2
; * sprite1.x > sprite2.x
; * sprite2.y > sprite1.y2
; * sprite1.y > sprite2.y2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.proc detect_collisions
    lda #$00
    sta num_collision_results

    lda #<collision_component_container
    sta ptr1

    lda #>collision_component_container
    sta ptr1 + 1

    lda #<collision_results
    sta ptr4

    lda #>collision_results
    sta ptr4 + 1

    ldy #$00
    tya                                     ; push y to stack
    pha

    lda num_collision_components
    sta var10
    cmp #$00
    bne @first_loop                         ; early out if list is empty
    rts
@first_loop:
    pla                                     ; get y from stack
    tay

    lda var10
    cmp #$00
    bne :+
    rts
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
    sta var1                               ; var1 => x pos
    iny

    lda (ptr2), y
    sta var2                               ; var2 => y pos
    iny

    iny                                     ; check if this component is active or not
    lda (ptr2), Y
    sta var3
    lda #COLLISION_CMP
    bit var3
    bne :+

    dec var10
    jmp @first_loop

 :  pla                                     ; get collision offset from buffer
    tay

    lda (ptr1), y                      ; collision mask
    sta var3
    iny

    lda (ptr1), y                      ; collision layer
    sta var4
    iny

    lda (ptr1), y                      ; xMin => xMinOffset + xPos  =>     var5
    clc
    adc var1
    sta var5
    iny

    lda (ptr1), Y                      ; xMax => xMinOffset + xPos =>      var6
    clc
    adc var1
    sta var6
    iny

    lda (ptr1), Y                      ; yMin => yMaxOffset + yPos =>      var1
    clc
    adc var2
    sta var1
    iny

    lda (ptr1), Y                      ; yMax => yMaxOffset + yPos =>      var2
    clc
    adc var2
    sta var2
    iny

    tya                                     ; push y to stack
    pha

    ; prepare the variables and there we go
    lda num_collision_components
    sta var9
    ldy #$00

; let the maddness begin
@second_loop:
    lda var9
    cmp #$00
    bne :+
    dec var10
    jmp @first_loop
    ; lets get this other collision component
:   ; lda var9                               ; if both items (first and second loop) have the same offset continue to the next item
    cmp var10
    bne :+
    tya
    clc
    adc #COLL_COMP_SIZE
    tay
    dec var9
    jmp @second_loop

:   lda (ptr1), y                      ; Get entity address lo byte
    sta ptr3
    iny

    lda (ptr1), y                      ; Get entity address hi byte
    sta ptr3 + 1
    iny

    iny                                     ; ignore mask, get to the layer directly
    ; first check the collision layer .. if the item from the first loop doesn't have it on his mask .. skip
    lda (ptr1), y                      ; Get entity address hi byte
    and var3                               ; compare with mask

    bne :+                                  ; skip this and go to the next item
    tya
    clc
    adc #$05                                ; increase y by 3
    tay
    dec var9
    jmp @second_loop

:   tya                                     ; push y to stack
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (ptr3), y
    sta var7                               ; var1 => x pos
    iny

    lda (ptr3), y
    sta var8                               ; var2 => y pos
    iny

    iny                                     ; check if this component is active or not
    lda (ptr3), Y
    sta tmp2

    pla                                     ; get collision offset from buffer
    tay

    lda #COLLISION_CMP
    bit tmp2
    bne :+
    tya
    clc
    adc #$05                                ; increase y by 3
    tay
    dec var9
    jmp @second_loop
    dec var9
    jmp @second_loop

 :  jmp @achje_jmp
@inbetween_jump:
    jmp @second_loop
@achje_jmp:
    ; do the actual collision checks, check for the cases where you DON'T have a collision
    ; less instructions -> faster
    lda #$00
    sta tmp1                              ; use tmp1 for the result -> 1 coll .. 0 not

    iny
    ;1: sprite2.xMin > sprite1.xMax
    lda (ptr1), Y                      ; sprite2.xMin

    clc
    adc var7
    cmp var6                               ; var6 => sprite1.xMax
    bcs :+                                  ; cary set if sprite2.xMin > sprite1.xMax
    inc tmp1
:
    iny
    ;2: sprite1.xMin > sprite2.xMax
    lda (ptr1), Y                      ; sprite2.xMax
    clc
    adc var7
    sta tmp2
    lda var5                               ; var5 => sprite1.xMin
    cmp tmp2

    bcs :+                                  ; carry set if sprite2.xMin >= sprite2.xMax
    inc tmp1
:
    ;3: sprite2.y > sprite1.y2
    iny
    lda (ptr1), Y                      ; sprite2.yMin
    clc
    adc var8
    cmp var2                               ; var2 => sprite1.yMax
    bcs :+                                  ; s2min > s1max
    inc tmp1
:
    ;4: sprite1.y > sprite2.y2
    iny
    lda (ptr1), Y
    clc
    adc var8
    sta tmp2                              ; sprite2.yMax
    iny
    lda var1                               ; var1 => sprite1.yMin
    cmp tmp2
    bcs @continue_2nd_loop                  ; carry set if sprite1.yMin > sprite2.yMax
    inc tmp1
@continue_2nd_loop:   ; finito : if one of those checks was successfull, we don't have a collision and can continue
    dec var9
    lda tmp1
    cmp #$04
    bne @inbetween_jump

    ; We have a collision!
    ; just store indices of colliding components:


; commment_in later
    mult_with_constant num_collision_results, #4, tmp6
    ;calc_address_with_offset collision_results, tmp6, ptr4

    ldy tmp6
    lda ptr2
    sta (ptr4), Y
    iny

    lda ptr2 + 1
    sta (ptr4), Y
    iny

    lda ptr3
    sta (ptr4), Y
    iny

    lda ptr3 +1
    sta (ptr4), y

    inc num_collision_results
    jmp @inbetween_jump
    rts
.endproc
