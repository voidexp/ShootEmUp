;collision_component_container:
; list of all collision components
.rodata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; collision_component:
;    .byte collision_mask
;    .byte collision_layer
;    .byte width
;    .byte height
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COLL_COMP_SIZE = 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; COLLISION_LAYER:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ENEMY_LYR           = 1
PROJECTILE_LYR      = 2
PLAYER_LYR          = 4
TBD_1_LYR           = 8
TBD_2_LYR           = 16
TBD_3_LYR           = 32


.segment "RAM"
collision_component_container:  .res 160

num_collision_components:       .res 1

collision_results:              .res 20
num_collision_results:          .res 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT CODE .. reset all variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.code
init_collision_components:
    lda #$00
    sta num_collision_components
    sta num_collision_results
    rts 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CREATES COLLISION COMPONENT
; Args:
;   var_1               - collision mask
;   var_2               - collision layer
;   var_3               - width
;   var_4               - height

;   address_1           - owner
;
; Result:
;   address_2           - address of the coll component
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

create_collision_component:
    ; calculate offset in current component buffer
    mult_with_constant num_collision_components, #COLL_COMP_SIZE, var_5

    calc_address_with_offset collision_component_container, var_5, address_2 ; use address_2 as address_3 is return address

    ldy #$00                                ; owner lo
    lda address_1
    sta (address_2), y

    iny
    lda address_1 + 1                       ; owner hi
    sta (address_2), y
    iny

    lda var_1                               ; collision mask
    sta (address_2), y
    iny

    lda var_2                               ; collision layer
    sta (address_2), y
    iny

    mult_with_constant var_3, #4, var_5     ; multiply by eight -> size in pixel
    lda var_5                               ; xMin
    clc
    eor #$ff
    adc #$01
    sta (address_2), y
    iny

    lda var_5                               ; xMax
    sta (address_2), y
    iny

    mult_with_constant var_4, #4, var_5     ; multiply by eight -> size in pixel
    lda var_5                               ; yMin
    clc
    eor #$ff
    adc #$01
    sta (address_2), y
    iny

    lda var_5                               ; yMax
    sta (address_2), y
    iny

    inc num_collision_components
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PERFORM CD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_collision_components:
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
    sta var_1
    ldy #$00

    lda #<collision_results
    sta address_2

    lda #>collision_results
    sta address_2 + 1
    ; process collision
:
    lda (address_2), Y                      ; Get first entity address lo byte     
	sta address_3
    iny

    lda (address_2), y                      ; Get first entity address hi byte
	sta address_3 + 1
    iny

    lda (address_2), Y                      ; get address of second entity 
    sta address_4 
    iny

    lda (address_2), Y
    sta address_4 + 1
    iny 

    tya 
    pha

    ldy #$00
    lda #$ff
    sta (address_3), Y                      ; set xpos to nirvana -> hide entity
    sta (address_4), y

    pla
    tay

    dec var_1

    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; actual CD
; instead of check if there IS a collision, check if there ISN'T
; * sprite2.x > sprite1.x2
; * sprite1.x > sprite2.x
; * sprite2.y > sprite1.y2
; * sprite1.y > sprite2.y2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
detect_collisions:
    lda #$00
    sta num_collision_results

    lda #<collision_component_container
    sta address_1

    lda #>collision_component_container
    sta address_1 + 1

    lda #<collision_results
    sta address_4

    lda #>collision_results
    sta address_4 + 1

    ldy #$00
    tya                                     ; push y to stack
    pha

    lda num_collision_components
    sta var_10
    cmp #$00
    bne @first_loop                         ; early out if list is empty
    rts
@first_loop:
    pla                                     ; get y from stack
    tay 

    lda var_10
    cmp #$00
    bne :+
    rts
:   lda (address_1), y                      ; Get entity address lo byte
	sta address_2
    iny

    lda (address_1), y                      ; Get entity address hi byte
	sta address_2 + 1
    iny

    tya                                     ; push y to stack 
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (address_2), y
    sta var_1                               ; !var_1 => x pos
    iny

    lda (address_2), y
    sta var_2                               ; !var_2 => y pos

    pla                                     ; get collision offset from buffer
    tay

    lda (address_1), y                      ; collision mask   
    sta var_3
    iny

    lda (address_1), y                      ; collision layer   
    sta var_4
    iny

    lda (address_1), y                      ; xMin => xMinOffset + xPos  =>     var_5
    clc
    adc var_1
    sta var_5
    iny

    lda (address_1), Y                      ; xMax => xMinOffset + xPos =>      var_6
    clc 
    adc var_1
    sta var_6
    iny 

    lda (address_1), Y                      ; xMax => xMaxOffset + xPos =>      var_1
    clc 
    adc var_2
    sta var_1
    iny 
    
    lda (address_1), Y                      ; xMax => xMaxOffset + xPos =>      var_2
    clc 
    adc var_2
    sta var_2
    iny 

    tya                                     ; push y to stack
    pha

    ; prepare the variables and there we go
    lda num_collision_components
    sta var_9
    ldy #$00

; let the maddness begin
@second_loop:
    lda var_9
    cmp #$00
    bne :+
    dec var_10
    jmp @first_loop
    ; lets get this other collision component
:   ; lda var_9                               ; if both items (first and second loop) have the same offset continue to the next item
    cmp var_10
    bne :+
    tya
    clc
    adc #COLL_COMP_SIZE
    tay
    dec var_9
    jmp @second_loop

:   lda (address_1), y                      ; Get entity address lo byte
	sta address_3
    iny

    lda (address_1), y                      ; Get entity address hi byte
	sta address_3 + 1
    iny

    iny                                     ; ignore mask, get to the layer directly
    ; first check the collision layer .. if the item from the first loop doesn't have it on his mask .. skip
    lda (address_1), y                      ; Get entity address hi byte
	and var_3                               ; compare with mask
    
    bne :+                                  ; skip this and go to the next item
    tya
    clc
    adc #$05                                ; increase y by 3
    tay
    dec var_9   
    jmp @second_loop

:   tya                                     ; push y to stack 
    pha

    ldy #$00                                ; get x, y position from the entity
    lda (address_3), y
    sta var_7                               ; !var_1 => x pos
    iny

    lda (address_3), y
    sta var_8                               ; !var_2 => y pos

    pla                                     ; get collision offset from buffer
    tay

    jmp @achje_jmp
@inbetween_jump:
    jmp @second_loop
@achje_jmp:
    ; get the actual collision checks
    lda #$00 
    sta temp_1                              ; use temp_1 for the result -> 1 coll .. 0 not

    iny 
    lda (address_1), Y                      ; xMin
    ; sprite2.x > sprite1.x2
    clc
    adc var_7
    cmp var_6                               ; var_6 => xMax
    bcs :+ ; bcs -> sprite2.xMin > sprite1.xMax
    inc temp_1
: 
    iny 
    lda (address_1), Y                      ; xMax
    clc
    adc var_7
    sta temp_2
    lda var_5                               ; var_5 => xMin
    cmp temp_2
    ; sprite1.xMin > sprite2.xMax
    bcs :+ ; carry should be set s1xMin >= s2xMax
    inc temp_1
:
    ; sprite2.y > sprite1.y2
    iny 
    lda (address_1), Y                      ; yMin
    clc
    adc var_8
    cmp var_2                      
    bcs :+  ; s2min > s1max
    inc temp_1
:
    ; sprite1.y > sprite2.y2
    iny 
    lda (address_1), Y
    clc
    adc var_8
    sta temp_2                              ; s2 yMax
    iny
    lda var_1
    cmp temp_2
    bcs :+
    inc temp_1
:   ;finito
    dec var_9
    lda temp_1
    cmp #$04
    bne @inbetween_jump

    ; We have a collision!
    ; just store indices of colliding components:


; commment_in later
    mult_with_constant num_collision_results, #4, temp_6
    ;calc_address_with_offset collision_results, temp_6, address_4

    ldy temp_6
    lda address_2
    sta (address_4), Y
    iny

    lda address_2 + 1
    sta (address_4), Y
    iny

    lda address_3
    sta (address_4), Y
    iny

    lda address_3 +1
    sta (address_4), y


    inc num_collision_results
    jmp @inbetween_jump
    rts
